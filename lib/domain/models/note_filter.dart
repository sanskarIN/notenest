enum NoteCollection { all, favorites, archive, trash }

final class NoteFilter {
  const NoteFilter({
    this.collection = NoteCollection.all,
    this.query = '',
    this.folder,
    this.tag,
  });

  final NoteCollection collection;
  final String query;
  final String? folder;
  final String? tag;

  NoteFilter copyWith({
    NoteCollection? collection,
    String? query,
    String? folder,
    String? tag,
    bool clearFolder = false,
    bool clearTag = false,
  }) {
    return NoteFilter(
      collection: collection ?? this.collection,
      query: query ?? this.query,
      folder: clearFolder ? null : folder ?? this.folder,
      tag: clearTag ? null : tag ?? this.tag,
    );
  }
}
