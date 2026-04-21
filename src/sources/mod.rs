use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

pub mod cubari;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MangaInfo {
    pub id: String,
    pub title: String,
    pub cover_url: Option<String>,
    pub source: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Chapter {
    pub id: String,
    pub title: String,
    pub number: f32,
    pub read: bool,
}

#[async_trait]
pub trait MangaSource: Send + Sync {
    async fn search(&self, query: &str) -> Result<Vec<MangaInfo>>;
    async fn get_chapters(&self, manga_id: &str) -> Result<Vec<Chapter>>;
    async fn get_pages(&self, chapter_id: &str) -> Result<Vec<String>>;
}

pub fn get_source(name: &str) -> Box<dyn MangaSource> {
    match name {
        "cubari" => Box::new(cubari::CubariSource::new()),
        _ => Box::new(cubari::CubariSource::new()),
    }
}
