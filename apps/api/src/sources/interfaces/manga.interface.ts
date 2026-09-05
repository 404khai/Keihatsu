export interface Manga {
  id: string; // Typically the URL or a slug
  url: string;
  title: string;
  thumbnailUrl: string;
  description?: string;
  author?: string;
  artist?: string;
  status?: string; // e.g., "Ongoing", "Completed"
  genres?: string[];
  sourceId: string;
}

export interface Chapter {
  id: string; // Typically the URL or a slug
  url: string;
  name: string;
  dateUpload: number; // Timestamp
  chapterNumber: number;
  scanlator?: string;
}

export interface Page {
  index: number;
  imageUrl: string;
  url: string; // The page URL (sometimes needed for referer)
}

export interface MangasPage {
  mangas: Manga[];
  hasNextPage: boolean;
}
