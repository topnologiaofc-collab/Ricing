use std::time::Duration;

use anyhow::Result;
use crossterm::event;
use image::DynamicImage;
use ratatui::{backend::CrosstermBackend, Terminal};
use ratatui_image::picker::Picker;
use tokio::sync::mpsc;

use crate::{
    history::HistoryDb,
    input::{self, Action},
    reader::{self, ReaderState},
    sources::{get_source, Chapter, MangaInfo},
    ui,
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Screen {
    Home,
    Search,
    Results,
    Chapters,
    Reader,
}

pub enum AsyncMessage {
    SearchLoaded(Result<Vec<MangaInfo>>),
    ChaptersLoaded(Result<Vec<Chapter>>),
    PagesLoaded(Result<Vec<String>>),
    ImageLoaded {
        idx: usize,
        image: Result<DynamicImage>,
    },
}

pub struct App {
    pub screen: Screen,
    pub query: String,
    pub results: Vec<MangaInfo>,
    pub selected_result: usize,
    pub selected_manga: Option<MangaInfo>,
    pub chapters: Vec<Chapter>,
    pub selected_chapter: usize,
    pub reader: Option<ReaderState>,
    pub history: HistoryDb,
    tx: mpsc::UnboundedSender<AsyncMessage>,
    rx: mpsc::UnboundedReceiver<AsyncMessage>,
}

impl App {
    pub fn new(history: HistoryDb) -> Self {
        let (tx, rx) = mpsc::unbounded_channel();
        Self {
            screen: Screen::Home,
            query: String::new(),
            results: Vec::new(),
            selected_result: 0,
            selected_manga: None,
            chapters: Vec::new(),
            selected_chapter: 0,
            reader: None,
            history,
            tx,
            rx,
        }
    }

    pub async fn run(
        &mut self,
        terminal: &mut Terminal<CrosstermBackend<std::io::Stdout>>,
        picker: &Picker,
    ) -> Result<()> {
        loop {
            self.drain_async_messages();

            terminal.draw(|f| ui::draw(f, self, picker))?;

            if event::poll(Duration::from_millis(80))? {
                let evt = event::read()?;
                if let Some(action) = input::handle_event(evt, &self.screen) {
                    if self.apply_action(action).await? {
                        break;
                    }
                }
            }
        }
        Ok(())
    }

    fn drain_async_messages(&mut self) {
        while let Ok(msg) = self.rx.try_recv() {
            match msg {
                AsyncMessage::SearchLoaded(Ok(results)) => {
                    self.results = results;
                    self.selected_result = 0;
                    self.screen = Screen::Results;
                }
                AsyncMessage::SearchLoaded(Err(_)) => {}
                AsyncMessage::ChaptersLoaded(Ok(chapters)) => {
                    self.chapters = chapters;
                    self.selected_chapter = 0;
                    self.screen = Screen::Chapters;
                }
                AsyncMessage::ChaptersLoaded(Err(_)) => {}
                AsyncMessage::PagesLoaded(Ok(pages)) => {
                    self.reader = Some(ReaderState::new(pages));
                    self.screen = Screen::Reader;
                    self.spawn_prefetch();
                }
                AsyncMessage::PagesLoaded(Err(_)) => {}
                AsyncMessage::ImageLoaded { idx, image } => {
                    if let (Some(reader), Ok(img)) = (self.reader.as_mut(), image) {
                        reader.upsert_image(idx, img);
                    }
                }
            }
        }
    }

    async fn apply_action(&mut self, action: Action) -> Result<bool> {
        match action {
            Action::Quit => return Ok(true),
            Action::Back => self.handle_back(),
            Action::Up => self.move_selection_up(),
            Action::Down => self.move_selection_down(),
            Action::Select => self.handle_select(),
            Action::Char(c) => {
                if matches!(self.screen, Screen::Search) {
                    self.query.push(c);
                }
                if matches!(self.screen, Screen::Home) && c == '/' {
                    self.screen = Screen::Search;
                }
            }
            Action::Backspace => {
                if matches!(self.screen, Screen::Search) {
                    self.query.pop();
                }
            }
            Action::ToggleMode => {
                if let Some(reader) = self.reader.as_mut() {
                    reader.toggle_mode();
                }
            }
        }

        if let (Some(manga), Some(reader)) = (&self.selected_manga, &self.reader) {
            if let Some(ch) = self.chapters.get(self.selected_chapter) {
                let _ = self
                    .history
                    .save_progress(&manga.id, &ch.id, reader.current_page);
            }
        }

        Ok(false)
    }

    fn handle_back(&mut self) {
        self.screen = match self.screen {
            Screen::Home => Screen::Home,
            Screen::Search => Screen::Home,
            Screen::Results => Screen::Search,
            Screen::Chapters => Screen::Results,
            Screen::Reader => Screen::Chapters,
        }
    }

    fn move_selection_up(&mut self) {
        match self.screen {
            Screen::Results => self.selected_result = self.selected_result.saturating_sub(1),
            Screen::Chapters => self.selected_chapter = self.selected_chapter.saturating_sub(1),
            Screen::Reader => {
                if let Some(reader) = self.reader.as_mut() {
                    reader.prev_page();
                    self.spawn_prefetch();
                }
            }
            _ => {}
        }
    }

    fn move_selection_down(&mut self) {
        match self.screen {
            Screen::Results => {
                if self.selected_result + 1 < self.results.len() {
                    self.selected_result += 1;
                }
            }
            Screen::Chapters => {
                if self.selected_chapter + 1 < self.chapters.len() {
                    self.selected_chapter += 1;
                }
            }
            Screen::Reader => {
                if let Some(reader) = self.reader.as_mut() {
                    reader.next_page();
                    self.spawn_prefetch();
                }
            }
            _ => {}
        }
    }

    fn handle_select(&mut self) {
        match self.screen {
            Screen::Home => self.screen = Screen::Search,
            Screen::Search => self.spawn_search(),
            Screen::Results => {
                if let Some(manga) = self.results.get(self.selected_result).cloned() {
                    self.selected_manga = Some(manga.clone());
                    self.spawn_load_chapters(manga.id);
                }
            }
            Screen::Chapters => {
                if let Some(ch) = self.chapters.get(self.selected_chapter).cloned() {
                    if let Some(manga) = &self.selected_manga {
                        let _ = self.history.mark_read(&manga.id, &ch.id);
                    }
                    self.spawn_load_pages(ch.id);
                }
            }
            Screen::Reader => {}
        }
    }

    fn spawn_search(&self) {
        let tx = self.tx.clone();
        let query = self.query.clone();
        tokio::spawn(async move {
            let source = get_source("cubari");
            let _ = tx.send(AsyncMessage::SearchLoaded(source.search(&query).await));
        });
    }

    fn spawn_load_chapters(&self, manga_id: String) {
        let tx = self.tx.clone();
        tokio::spawn(async move {
            let source = get_source("cubari");
            let _ = tx.send(AsyncMessage::ChaptersLoaded(
                source.get_chapters(&manga_id).await,
            ));
        });
    }

    fn spawn_load_pages(&self, chapter_id: String) {
        let tx = self.tx.clone();
        tokio::spawn(async move {
            let source = get_source("cubari");
            let _ = tx.send(AsyncMessage::PagesLoaded(
                source.get_pages(&chapter_id).await,
            ));
        });
    }

    fn spawn_prefetch(&self) {
        let Some(reader) = &self.reader else {
            return;
        };
        let start = reader.current_page;
        let pages = reader.pages.clone();

        for idx in [start, start.saturating_add(1), start.saturating_add(2)] {
            if idx >= pages.len() || reader.cache.contains_key(&idx) {
                continue;
            }
            let tx = self.tx.clone();
            let url = pages[idx].clone();
            tokio::spawn(async move {
                let image = reader::fetch_image(url).await;
                let _ = tx.send(AsyncMessage::ImageLoaded { idx, image });
            });
        }
    }
}
