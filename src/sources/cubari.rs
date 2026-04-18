use std::{collections::BTreeMap, time::Duration};

use anyhow::{anyhow, Context, Result};
use reqwest::Client;
use serde::Deserialize;

use super::{Chapter, MangaInfo, MangaSource};

#[derive(Clone)]
pub struct CubariSource {
    client: Client,
}

impl CubariSource {
    pub fn new() -> Self {
        let client = Client::builder()
            .timeout(Duration::from_secs(10))
            .user_agent("manga-rs/0.1 (terminal reader)")
            .build()
            .expect("valid reqwest client");
        Self { client }
    }

    fn parse_query(query: &str) -> Result<(String, String)> {
        let normalized = query
            .trim()
            .trim_start_matches("https://")
            .trim_start_matches("http://")
            .trim_start_matches("proxy.cubari.moe/read/")
            .trim_start_matches("proxy.cubari.moe/")
            .trim_start_matches("cubari.moe/read/")
            .trim_start_matches("cubari.moe/")
            .trim_matches('/');

        let parts: Vec<&str> = normalized.split('/').filter(|p| !p.is_empty()).collect();
        if parts.len() < 2 {
            return Err(anyhow!(
                "query inválida; use formato gist/slug ou imgur/slug"
            ));
        }

        let proxy = parts[0].to_lowercase();
        if proxy != "gist" && proxy != "imgur" {
            return Err(anyhow!("proxy não suportado: {proxy}"));
        }
        let slug = parts[1].to_string();
        Ok((proxy, slug))
    }
}

#[derive(Debug, Deserialize)]
struct SeriesResponse {
    title: Option<String>,
    cover: Option<String>,
    chapters: Option<BTreeMap<String, ChapterEntry>>,
}

#[derive(Debug, Deserialize)]
struct ChapterEntry {
    title: Option<String>,
}

#[derive(Debug, Deserialize)]
struct ChapterResponse {
    pages: Option<Vec<String>>,
    groups: Option<BTreeMap<String, GroupData>>,
}

#[derive(Debug, Deserialize)]
struct GroupData {
    pages: Option<Vec<String>>,
}

#[async_trait::async_trait]
impl MangaSource for CubariSource {
    async fn search(&self, query: &str) -> Result<Vec<MangaInfo>> {
        let (proxy, slug) = Self::parse_query(query)?;
        let url = format!("https://proxy.cubari.moe/read/api/{proxy}/series/{slug}/");
        let data: SeriesResponse = self
            .client
            .get(&url)
            .send()
            .await
            .with_context(|| format!("falha ao consultar {url}"))?
            .error_for_status()?
            .json()
            .await?;

        Ok(vec![MangaInfo {
            id: format!("{proxy}/{slug}"),
            title: data.title.unwrap_or_else(|| slug.clone()),
            cover_url: data.cover,
            source: "cubari".to_string(),
        }])
    }

    async fn get_chapters(&self, manga_id: &str) -> Result<Vec<Chapter>> {
        let (proxy, slug) = Self::parse_query(manga_id)?;
        let url = format!("https://proxy.cubari.moe/read/api/{proxy}/series/{slug}/");
        let data: SeriesResponse = self
            .client
            .get(&url)
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;

        let mut chapters = data
            .chapters
            .unwrap_or_default()
            .into_iter()
            .map(|(chapter_id, entry)| {
                let number = chapter_id.parse::<f32>().unwrap_or(0.0);
                Chapter {
                    id: format!("{proxy}|{slug}|{chapter_id}"),
                    title: entry
                        .title
                        .unwrap_or_else(|| format!("Capítulo {chapter_id}")),
                    number,
                    read: false,
                }
            })
            .collect::<Vec<_>>();

        chapters.sort_by(|a, b| {
            a.number
                .partial_cmp(&b.number)
                .unwrap_or(std::cmp::Ordering::Equal)
        });

        Ok(chapters)
    }

    async fn get_pages(&self, chapter_id: &str) -> Result<Vec<String>> {
        let parts: Vec<&str> = chapter_id.split('|').collect();
        if parts.len() != 3 {
            return Err(anyhow!("chapter_id inválido"));
        }
        let (proxy, slug, chapter) = (parts[0], parts[1], parts[2]);
        let primary =
            format!("https://proxy.cubari.moe/read/api/{proxy}/chapter/{slug}/{chapter}/");
        let backup = format!("https://proxy.cubari.moe/read/api/{proxy}/series/{slug}/{chapter}/");

        for url in [primary, backup] {
            let response = self.client.get(&url).send().await?;
            if !response.status().is_success() {
                continue;
            }

            let data: ChapterResponse = response.json().await?;
            if let Some(pages) = data.pages {
                if !pages.is_empty() {
                    return Ok(pages);
                }
            }
            if let Some(groups) = data.groups {
                for group in groups.into_values() {
                    if let Some(pages) = group.pages {
                        if !pages.is_empty() {
                            return Ok(pages);
                        }
                    }
                }
            }
        }

        Err(anyhow!("não foi possível obter páginas do capítulo"))
    }
}
