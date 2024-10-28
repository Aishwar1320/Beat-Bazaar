class Song {
  final String songName;
  final String artistName;
  final String albumArtImagePath;
  final String audioPath;
  int playCount;
  final String id;
  bool isFavorite;

  Song({
    required this.songName,
    required this.artistName,
    required this.albumArtImagePath,
    required this.audioPath,
    this.playCount = 0,
    required this.id,
    this.isFavorite = false,
  });
}
