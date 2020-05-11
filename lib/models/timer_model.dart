import 'package:api_client/models/model.dart';
import 'package:api_client/offline_repository/repository.dart';
import 'package:api_client/offline_repository/repository_interface.dart';
import 'package:meta/meta.dart';

/// Represents a timer for an activity
class TimerModel implements Model {
  /// Constructor for timer
  TimerModel({
    @required this.startTime,
    @required this.progress,
    @required this.fullLength,
    @required this.paused,
    this.key,
  });

  /// Constructor for the timer from json.
  TimerModel.fromJson(Map<String, dynamic> json) {
    if (json == null) {
      throw const FormatException(
          '[TimerModel]: Cannot initialize from null');
    }
      startTime = DateTime.fromMillisecondsSinceEpoch(json['startTime']);
      progress = json['progress'];
      fullLength = json['fullLength'];
      paused = json['paused'];
      key = json['key'];
  }

  /// The time for when the timer started.
  DateTime startTime;

  ///Key for identifying the timer
  int key;

  /// The progress of the timer
  int progress;

  /// The full timer length
  int fullLength;

  /// Bool if the timer is paused or not
  bool paused;

  @override
  /// Offline id
  int offlineId;

  @override
  /// Get offline id
  int getOfflineId() {
    return offlineId;
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startTime': startTime.millisecondsSinceEpoch ?? 'null',
      'progress': progress ?? 'null',
      'fullLength': fullLength ?? 'null',
      'paused': paused ?? 'null',
      'key' : key
    };
  }

  /// getter for repository
  static IOfflineRepository<Model> offline() {
    return OfflineRepository((TimerModel).toString());
  }

}