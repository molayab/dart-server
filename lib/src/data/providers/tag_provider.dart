import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dart_server/src/data/entities/track.dart';
import 'package:dart_server/src/domain/provider_interfaces/tag_provider_interface.dart';
import 'package:dart_tags/dart_tags.dart';

class TagProvider implements TagProviderInterface {
  TagProcessor _tagProcessor;

  TagProvider() {
    _tagProcessor = TagProcessor();
  }

  Future<List<Tag>> getTagsFromByteChunk(Future<List<int>> steam) async {
    return await _tagProcessor.getTagsFromByteArray(steam);
  }

  Future<TrackEntity> getTrackEntityFromFile(File file) async {
    final bytes = file.readAsBytes();
    var tags = await getTagsFromByteChunk(bytes);

    // supporting mp3 just for now...
    final tag = tags.firstWhere((element) {
      return (element.type == "ID3" && element.version.startsWith("2."));
    });

    final resourceId = sha1.convert(await bytes);
    return _buildTrackEntityFromTagAndStorageId(
        tag.tags, resourceId.toString());
  }

  TrackEntity _buildTrackEntityFromTagAndStorageId(
      Map<String, dynamic> tags, String id) {
    final title = tags['title'] as String;
    final resourceUri = "stream::${id}";

    var track = TrackEntity(title, resourceUri);
    track.album = tags['album'] as String;
    track.artist = tags['artist'] as String;
    track.albumArtist = tags['TPE2'] as String;
    track.year = int.parse(tags['year'] as String);
    track.genre = tags['genre'] as String;
    track.originalArtist = tags['TOPE'] as String;
    track.track = int.parse(tags['track'] as String);
    track.label = tags['TPUB'] as String;
    track.bpm = double.parse(tags['TBPM'] as String);
    track.key = tags['TKEY'] as String;
    track.contentGroupDescription = tags['TIT1'] as String;

    // TODO: Extract cover image.
    return track;
  }
}
