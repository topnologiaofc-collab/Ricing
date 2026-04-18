mod app;
mod history;
mod input;
mod reader;
mod sources;
mod ui;

use std::{io::{self, stdout}, panic};

use anyhow::Result;
use crossterm::{
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{backend::CrosstermBackend, Terminal};
use ratatui_image::picker::Picker;

use crate::{app::App, history::HistoryDb};

#[tokio::main]
async fn main() -> Result<()> {
    let picker = Picker::from_query_stdio()?;
    install_panic_hook();

    enable_raw_mode()?;
    let mut out = stdout();
    execute!(out, EnterAlternateScreen)?;

    let backend = CrosstermBackend::new(out);
    let mut terminal = Terminal::new(backend)?;

    let history = HistoryDb::open()?;
    let mut app = App::new(history);
    let result = app.run(&mut terminal, &picker).await;

    restore_terminal(&mut terminal)?;
    result
}

fn install_panic_hook() {
    let original = panic::take_hook();
    panic::set_hook(Box::new(move |info| {
        let _ = disable_raw_mode();
        let mut out = io::stdout();
        let _ = execute!(out, LeaveAlternateScreen);
        original(info);
    }));
}

fn restore_terminal(terminal: &mut Terminal<CrosstermBackend<std::io::Stdout>>) -> Result<()> {
    disable_raw_mode()?;
    execute!(terminal.backend_mut(), LeaveAlternateScreen)?;
    terminal.show_cursor()?;
    Ok(())
}
