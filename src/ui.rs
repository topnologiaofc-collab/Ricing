use ratatui::{
    layout::{Alignment, Constraint, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Tabs, Wrap},
    Frame,
};
use ratatui_image::picker::Picker;

use crate::{
    app::{App, Screen},
    reader,
};

pub fn draw(frame: &mut Frame<'_>, app: &mut App, picker: &Picker) {
    let root = Layout::vertical([
        Constraint::Length(3),
        Constraint::Min(5),
        Constraint::Length(2),
    ])
    .split(frame.size());

    draw_header(frame, root[0], app);

    match app.screen {
        Screen::Home => draw_home(frame, root[1], app),
        Screen::Search => draw_search(frame, root[1], app),
        Screen::Results => draw_results(frame, root[1], app),
        Screen::Chapters => draw_chapters(frame, root[1], app),
        Screen::Reader => draw_reader(frame, root[1], app, picker),
    }

    draw_footer(frame, root[2], app);
}

fn draw_header(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let titles = ["Home", "Search", "Results", "Chapters", "Reader"]
        .iter()
        .map(|t| Line::from(Span::styled(*t, Style::default().fg(Color::White))))
        .collect::<Vec<_>>();

    let selected = match app.screen {
        Screen::Home => 0,
        Screen::Search => 1,
        Screen::Results => 2,
        Screen::Chapters => 3,
        Screen::Reader => 4,
    };

    let tabs = Tabs::new(titles)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("manga-rs • inspirado no manga-tui"),
        )
        .select(selected)
        .style(Style::default().fg(Color::Gray))
        .highlight_style(
            Style::default()
                .fg(Color::Cyan)
                .add_modifier(Modifier::BOLD),
        )
        .divider("|");

    frame.render_widget(tabs, area);
}

fn draw_footer(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let help = match app.screen {
        Screen::Home => " / buscar  • Enter abrir busca  • q sair ",
        Screen::Search => " Digite gist/slug ou imgur/slug  • Enter buscar  • Esc voltar ",
        Screen::Results => " ↑↓ navegar  • Enter abrir manga  • Esc voltar ",
        Screen::Chapters => " ↑↓ navegar  • Enter abrir capítulo  • Esc voltar ",
        Screen::Reader => " ↑↓ páginas  • m alterna modo  • q/Esc voltar ",
    };

    let status = Paragraph::new(help)
        .alignment(Alignment::Center)
        .style(Style::default().fg(Color::Black).bg(Color::Cyan))
        .block(Block::default().borders(Borders::ALL));

    frame.render_widget(status, area);
}

fn draw_home(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let body =
        Layout::horizontal([Constraint::Percentage(65), Constraint::Percentage(35)]).split(area);

    let entries = app.history.get_continue_reading().unwrap_or_default();
    let items = if entries.is_empty() {
        vec![ListItem::new("Nenhum progresso salvo ainda.")]
    } else {
        entries
            .into_iter()
            .map(|p| {
                ListItem::new(Line::from(vec![
                    Span::styled(p.manga_id, Style::default().fg(Color::Yellow)),
                    Span::raw(format!("  cap {}  pág {}", p.chapter_id, p.page + 1)),
                ]))
            })
            .collect::<Vec<_>>()
    };

    let history_list = List::new(items).block(
        Block::default()
            .title("Continue lendo")
            .borders(Borders::ALL)
            .border_style(Style::default().fg(Color::Blue)),
    );
    frame.render_widget(history_list, body[0]);

    let right_text = vec![
        Line::from(Span::styled(
            "Manga Reader TUI",
            Style::default().add_modifier(Modifier::BOLD),
        )),
        Line::from(""),
        Line::from("• Suporte a Cubari proxy"),
        Line::from("• Histórico local (sled)"),
        Line::from("• Navegação por teclado"),
        Line::from("• Prefetch assíncrono"),
        Line::from(""),
        Line::from(Span::styled(
            "Pressione / para buscar",
            Style::default().fg(Color::Green),
        )),
    ];

    let summary = Paragraph::new(right_text)
        .block(
            Block::default()
                .title("Dashboard")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Magenta)),
        )
        .wrap(Wrap { trim: true });
    frame.render_widget(summary, body[1]);
}

fn draw_search(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let popup = centered_rect(80, 35, area);
    frame.render_widget(Clear, popup);

    let chunks = Layout::vertical([Constraint::Length(3), Constraint::Min(1)]).split(popup);
    let input = Paragraph::new(app.query.as_str())
        .block(
            Block::default()
                .title("Buscar no proxy.cubari.moe")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Cyan)),
        )
        .style(Style::default().fg(Color::White));

    frame.render_widget(input, chunks[0]);

    let hints = Paragraph::new(vec![
        Line::from("Exemplos:"),
        Line::from("  gist/OnePunchMan"),
        Line::from("  imgur/abcd123"),
        Line::from("  https://proxy.cubari.moe/read/gist/OnePunchMan/"),
    ])
    .block(Block::default().borders(Borders::ALL).title("Ajuda"))
    .wrap(Wrap { trim: true });
    frame.render_widget(hints, chunks[1]);
}

fn draw_results(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let items = app
        .results
        .iter()
        .map(|m| {
            ListItem::new(Line::from(vec![
                Span::styled(&m.title, Style::default().fg(Color::Yellow)),
                Span::raw(format!("  [{}]", m.id)),
            ]))
        })
        .collect::<Vec<_>>();

    let mut state = ListState::default();
    state.select(Some(app.selected_result));

    let list = List::new(items)
        .block(
            Block::default()
                .title("Resultados")
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Blue)),
        )
        .highlight_style(
            Style::default()
                .bg(Color::Cyan)
                .fg(Color::Black)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▶ ");

    frame.render_stateful_widget(list, area, &mut state);
}

fn draw_chapters(frame: &mut Frame<'_>, area: Rect, app: &App) {
    let manga_title = app
        .selected_manga
        .as_ref()
        .map(|m| m.title.clone())
        .unwrap_or_else(|| "Capítulos".to_string());
    let manga_id = app
        .selected_manga
        .as_ref()
        .map(|m| m.id.clone())
        .unwrap_or_default();

    let items = app
        .chapters
        .iter()
        .map(|ch| {
            let read = app.history.is_read(&manga_id, &ch.id).unwrap_or(false);
            let icon = if read { "✓" } else { "•" };
            let style = if read {
                Style::default().fg(Color::DarkGray)
            } else {
                Style::default().fg(Color::White)
            };
            ListItem::new(Line::from(vec![
                Span::styled(format!("{icon} "), style),
                Span::styled(ch.title.clone(), style),
            ]))
        })
        .collect::<Vec<_>>();

    let mut state = ListState::default();
    state.select(Some(app.selected_chapter));

    let list = List::new(items)
        .block(
            Block::default()
                .title(format!("Capítulos • {manga_title}"))
                .borders(Borders::ALL)
                .border_style(Style::default().fg(Color::Blue)),
        )
        .highlight_style(
            Style::default()
                .bg(Color::Cyan)
                .fg(Color::Black)
                .add_modifier(Modifier::BOLD),
        )
        .highlight_symbol("▶ ");

    frame.render_stateful_widget(list, area, &mut state);
}

fn draw_reader(frame: &mut Frame<'_>, area: Rect, app: &mut App, picker: &Picker) {
    let Some(reader_state) = app.reader.as_mut() else {
        frame.render_widget(Paragraph::new("Nenhum capítulo carregado"), area);
        return;
    };
    reader::draw_reader(frame, area, reader_state, picker);
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
