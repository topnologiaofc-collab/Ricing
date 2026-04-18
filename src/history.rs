use std::{env, path::PathBuf, time::{SystemTime, UNIX_EPOCH}};

use anyhow::Result;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProgressEntry {
    pub manga_id: String,
    pub chapter_id: String,
    pub page: usize,
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BookmarkEntry {
    pub manga_id: String,
    pub chapter_id: String,
    pub page: usize,
    pub timestamp: u64,
}

#[derive(Clone)]
pub struct HistoryDb {
    db: sled::Db,
}

impl HistoryDb {
    pub fn open() -> Result<Self> {
        let base = env::var("XDG_DATA_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| {
                let mut p = env::var("HOME").map(PathBuf::from).unwrap_or_default();
                p.push(".local/share");
                p
            });
        let path = base.join("manga-rs/db");
        std::fs::create_dir_all(&path)?;
        let db = sled::open(path)?;
        Ok(Self { db })
    }

    pub fn save_progress(&self, manga_id: &str, chapter_id: &str, page: usize) -> Result<()> {
        let payload = ProgressEntry {
            manga_id: manga_id.to_string(),
            chapter_id: chapter_id.to_string(),
            page,
            timestamp: now_ts(),
        };
        self.db.insert(
            format!("progress:{manga_id}"),
            serde_json::to_vec(&payload)?,
        )?;
        self.db.flush()?;
        Ok(())
    }

    pub fn get_progress(&self, manga_id: &str) -> Result<Option<ProgressEntry>> {
        let Some(raw) = self.db.get(format!("progress:{manga_id}"))? else {
            return Ok(None);
        };
        Ok(Some(serde_json::from_slice(&raw)?))
    }

    pub fn mark_read(&self, manga_id: &str, chapter_id: &str) -> Result<()> {
        self.db.insert(
            format!("read:{manga_id}:{chapter_id}"),
            now_ts().to_be_bytes().to_vec(),
        )?;
        self.db.flush()?;
        Ok(())
    }

    pub fn is_read(&self, manga_id: &str, chapter_id: &str) -> Result<bool> {
        Ok(self
            .db
            .contains_key(format!("read:{manga_id}:{chapter_id}"))?)
    }

    pub fn get_continue_reading(&self) -> Result<Vec<ProgressEntry>> {
        let mut entries = Vec::new();
        for item in self.db.scan_prefix("progress:") {
            let (_, v) = item?;
            let e: ProgressEntry = serde_json::from_slice(&v)?;
            entries.push(e);
        }
        entries.sort_by_key(|e| std::cmp::Reverse(e.timestamp));
        entries.truncate(5);
        Ok(entries)
    }

    pub fn add_bookmark(&self, manga_id: &str, chapter_id: &str, page: usize) -> Result<()> {
        let payload = BookmarkEntry {
            manga_id: manga_id.to_string(),
            chapter_id: chapter_id.to_string(),
            page,
            timestamp: now_ts(),
        };
        self.db.insert(
            format!("bookmark:{manga_id}:{chapter_id}:{page}"),
            serde_json::to_vec(&payload)?,
        )?;
        self.db.flush()?;
        Ok(())
    }

    pub fn remove_bookmark(&self, manga_id: &str, chapter_id: &str, page: usize) -> Result<()> {
        self.db
            .remove(format!("bookmark:{manga_id}:{chapter_id}:{page}"))?;
        self.db.flush()?;
        Ok(())
    }

    pub fn list_bookmarks(&self, manga_id: &str) -> Result<Vec<BookmarkEntry>> {
        let prefix = format!("bookmark:{manga_id}:");
        let mut entries = Vec::new();
        for item in self.db.scan_prefix(prefix) {
            let (_, v) = item?;
            entries.push(serde_json::from_slice(&v)?);
        }
        entries.sort_by_key(|e: &BookmarkEntry| std::cmp::Reverse(e.timestamp));
        Ok(entries)
    }
}

fn now_ts() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}
