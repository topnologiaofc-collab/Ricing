use std::collections::HashMap;

use anyhow::Result;
use image::DynamicImage;
use ratatui::{
    layout::{Alignment, Constraint, Layout},
    style::{Color, Style},
    text::Line,
    widgets::{Block, Borders, Paragraph},
    Frame,
};
use ratatui_image::picker::Picker;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ReadMode {
    Page,
    Webtoon,
}

pub struct ReaderState {
    pub pages: Vec<String>,
    pub current_page: usize,
    pub mode: ReadMode,
    pub cache: HashMap<usize, DynamicImage>,
}

impl ReaderState {
    pub fn new(pages: Vec<String>) -> Self {
        Self {
            pages,
            current_page: 0,
            mode: ReadMode::Page,
            cache: HashMap::new(),
        }
    }

    pub fn next_page(&mut self) {
        if self.current_page + 1 < self.pages.len() {
            self.current_page += 1;
        }
    }

    pub fn prev_page(&mut self) {
        if self.current_page > 0 {
            self.current_page -= 1;
        }
    }

    pub fn toggle_mode(&mut self) {
        self.mode = match self.mode {
            ReadMode::Page => ReadMode::Webtoon,
            ReadMode::Webtoon => ReadMode::Page,
        };
    }

    pub fn upsert_image(&mut self, index: usize, image: DynamicImage) {
        self.cache.insert(index, image);
    }
}

pub fn draw_reader(frame: &mut Frame<'_>, state: &mut ReaderState, picker: &Picker) {
    let chunks = Layout::vertical([Constraint::Min(1), Constraint::Length(1)]).split(frame.size());

    match state.mode {
        ReadMode::Page => draw_single(frame, chunks[0], state, picker),
        ReadMode::Webtoon => draw_webtoon(frame, chunks[0], state),
    }

    let info = Paragraph::new(Line::from(format!(
        "Página {}/{} | Modo: {:?} | ↑/↓ navega | m alterna modo | q volta",
        state.current_page.saturating_add(1),
        state.pages.len(),
        state.mode
    )))
    .alignment(Alignment::Center)
    .style(Style::default().fg(Color::Gray));
    frame.render_widget(info, chunks[1]);
}

fn draw_single(
    frame: &mut Frame<'_>,
    area: ratatui::layout::Rect,
    state: &mut ReaderState,
    _picker: &Picker,
) {
    let block = Block::default().borders(Borders::ALL).title("Reader");
    let inner = block.inner(area);
    frame.render_widget(block, area);

    if state.cache.contains_key(&state.current_page) {
        frame.render_widget(
            Paragraph::new("Imagem carregada (renderização inline temporariamente desativada)")
                .alignment(Alignment::Center),
            inner,
        );
    } else {
        frame.render_widget(
            Paragraph::new("Carregando imagem...").alignment(Alignment::Center),
            inner,
        );
    }
}

fn draw_webtoon(frame: &mut Frame<'_>, area: ratatui::layout::Rect, state: &mut ReaderState) {
    let block = Block::default().borders(Borders::ALL).title("Webtoon");
    let inner = block.inner(area);
    frame.render_widget(block, area);

    let mut lines = Vec::new();
    for idx in 0..state.pages.len() {
        let marker = if idx == state.current_page { ">" } else { " " };
        let loaded = if state.cache.contains_key(&idx) {
            "[img ok]"
        } else {
            "[baixando]"
        };
        lines.push(Line::from(format!("{marker} Página {:03} {loaded}", idx + 1)));
    }

    frame.render_widget(Paragraph::new(lines), inner);
}

pub async fn fetch_image(url: String) -> Result<DynamicImage> {
    let bytes = reqwest::get(url).await?.bytes().await?;
    Ok(image::load_from_memory(&bytes)?)
}
