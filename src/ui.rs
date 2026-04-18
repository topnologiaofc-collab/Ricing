use ratatui::{
    layout::{Alignment, Constraint, Layout, Rect},
    style::{Color, Modifier, Style},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph},
    Frame,
};
use ratatui_image::picker::Picker;

use crate::{app::{App, Screen}, reader};

pub fn draw(frame: &mut Frame<'_>, app: &mut App, picker: &Picker) {
    match app.screen {
        Screen::Home => draw_home(frame, app),
        Screen::Search => draw_search(frame, app),
        Screen::Results => draw_results(frame, app),
        Screen::Chapters => draw_chapters(frame, app),
        Screen::Reader => draw_reader(frame, app, picker),
    }
}

fn draw_home(frame: &mut Frame<'_>, app: &App) {
    let chunks = Layout::vertical([Constraint::Min(3), Constraint::Length(2)]).split(frame.size());
    let entries = app.history.get_continue_reading().unwrap_or_default();
    let items = if entries.is_empty() {
        vec![ListItem::new("Sem histórico ainda")] 
    } else {
        entries
            .into_iter()
            .map(|p| ListItem::new(format!("{} | cap {} | pág {}", p.manga_id, p.chapter_id, p.page + 1)))
            .collect()
    };

    let list = List::new(items).block(Block::default().title("Continue lendo").borders(Borders::ALL));
    frame.render_widget(list, chunks[0]);
    frame.render_widget(
        Paragraph::new("Atalhos: / buscar | Enter selecionar | q sair")
            .alignment(Alignment::Center)
            .style(Style::default().fg(Color::Gray)),
        chunks[1],
    );
}

fn draw_search(frame: &mut Frame<'_>, app: &App) {
    let area = centered_rect(70, 20, frame.size());
    frame.render_widget(Clear, area);
    let block = Block::default().title("Cubari slug (gist/slug ou imgur/slug)").borders(Borders::ALL);
    let input = Paragraph::new(app.query.as_str()).block(block);
    frame.render_widget(input, area);
}

fn draw_results(frame: &mut Frame<'_>, app: &App) {
    let items = app
        .results
        .iter()
        .map(|r| ListItem::new(r.title.clone()))
        .collect::<Vec<_>>();
    let mut state = ListState::default();
    state.select(Some(app.selected_result));

    let list = List::new(items)
        .block(Block::default().title("Resultados").borders(Borders::ALL))
        .highlight_style(Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD))
        .highlight_symbol("➤ ");

    frame.render_stateful_widget(list, frame.size(), &mut state);
}

fn draw_chapters(frame: &mut Frame<'_>, app: &App) {
    let manga_id = app.selected_manga.as_ref().map(|m| m.id.clone()).unwrap_or_default();
    let items = app
        .chapters
        .iter()
        .map(|c| {
            let read = app.history.is_read(&manga_id, &c.id).unwrap_or(false);
            let prefix = if read { "✓" } else { "•" };
            ListItem::new(format!("{prefix} {}", c.title))
        })
        .collect::<Vec<_>>();
    let mut state = ListState::default();
    state.select(Some(app.selected_chapter));

    let list = List::new(items)
        .block(Block::default().title("Capítulos").borders(Borders::ALL))
        .highlight_style(Style::default().fg(Color::Yellow).add_modifier(Modifier::BOLD))
        .highlight_symbol("➤ ");

    frame.render_stateful_widget(list, frame.size(), &mut state);
}

fn draw_reader(frame: &mut Frame<'_>, app: &mut App, picker: &Picker) {
    let Some(reader_state) = app.reader.as_mut() else {
        frame.render_widget(Paragraph::new("Nenhum capítulo carregado"), frame.size());
        return;
    };
    reader::draw_reader(frame, reader_state, picker);
}

fn centered_rect(percent_x: u16, percent_y: u16, r: Rect) -> Rect {
    let popup_layout = Layout::vertical([
        Constraint::Percentage((100 - percent_y) / 2),
        Constraint::Percentage(percent_y),
        Constraint::Percentage((100 - percent_y) / 2),
    ])
    .split(r);

    Layout::horizontal([
        Constraint::Percentage((100 - percent_x) / 2),
        Constraint::Percentage(percent_x),
        Constraint::Percentage((100 - percent_x) / 2),
    ])
    .split(popup_layout[1])[1]
}
