use crossterm::event::{Event, KeyCode, KeyEventKind};

use crate::app::Screen;

#[derive(Debug, Clone)]
pub enum Action {
    Up,
    Down,
    Select,
    Back,
    Quit,
    Char(char),
    Backspace,
    ToggleMode,
}

pub fn handle_event(event: Event, screen: &Screen) -> Option<Action> {
    let Event::Key(key) = event else {
        return None;
    };

    if key.kind != KeyEventKind::Press {
        return None;
    }

    match key.code {
        KeyCode::Up => Some(Action::Up),
        KeyCode::Down => Some(Action::Down),
        KeyCode::Enter => Some(Action::Select),
        KeyCode::Esc => {
            if matches!(screen, Screen::Home) {
                Some(Action::Quit)
            } else {
                Some(Action::Back)
            }
        }
        KeyCode::Char('q') => {
            if matches!(screen, Screen::Home) {
                Some(Action::Quit)
            } else {
                Some(Action::Back)
            }
        }
        KeyCode::Char('m') if matches!(screen, Screen::Reader) => Some(Action::ToggleMode),
        KeyCode::Backspace => Some(Action::Backspace),
        KeyCode::Char(c) => Some(Action::Char(c)),
        _ => None,
    }
}
