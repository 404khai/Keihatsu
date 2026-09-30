import { BadRequestException } from '@nestjs/common';

// Path segments are encoded individually so external source IDs cannot change the route.
const segment = (value: string) => {
  if (!value || value.length > 300 || /[\u0000-\u001f]/.test(value)) {
    throw new BadRequestException('Invalid notification destination');
  }
  return encodeURIComponent(value);
};

export const notificationLinks = {
  inbox: () => 'keihatsu://inbox',
  manga: (sourceId: string, mangaId: string) =>
    `keihatsu://manga/${segment(sourceId)}/${segment(mangaId)}`,
  chapter: (sourceId: string, mangaId: string, chapterId: string) =>
    `keihatsu://chapter/${segment(sourceId)}/${segment(mangaId)}/${segment(chapterId)}`,
  comment: (sourceId: string, mangaId: string, chapterId: string, commentId: string) =>
    `keihatsu://comment/${segment(sourceId)}/${segment(mangaId)}/${segment(chapterId)}/${segment(commentId)}`,
  announcement: (id: string) => `keihatsu://announcement/${segment(id)}`,
  update: () => 'keihatsu://settings/update',
};
