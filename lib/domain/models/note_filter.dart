enum NoteCollection { all, favorites, archive, trash }

enum NoteSort { updatedNewest, updatedOldest, titleAscending, titleDescending }

final class NoteFilter {
  const NoteFilter({
    this.collection = NoteCollection.all,
    this.query = '',
    this.folder,
    this.tag,
    this.sort = NoteSort.updatedNewest,
  });

  final NoteCollection collection;
  final String query;
  final String? folder;
  final String? tag;
  final NoteSort sort;

  NoteFilter copyWith({
    NoteCollection? collection,
    String? query,
    String? folder,
    String? tag,
    NoteSort? sort,
    bool clearFolder = false,
    bool clearTag = false,
  }) {
    return NoteFilter(
      collection: collection ?? this.collection,
      query: query ?? this.query,
      folder: clearFolder ? null : folder ?? this.folder,
      tag: clearTag ? null : tag ?? this.tag,
      sort: sort ?? this.sort,
    );
  }
}
