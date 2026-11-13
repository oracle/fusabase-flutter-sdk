// Copyright (c) 2015, 2025, Oracle and/or its affiliates.

//-----------------------------------------------------------------------------
//
// This software is dual-licensed to you under the Universal Permissive License
// (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
// 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
// either license.
//
// If you elect to accept the software under the Apache License, Version 2.0,
// the following applies:
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//-----------------------------------------------------------------------------

part of "../../storage.dart";

/// Abstract class representing a task for upload or download.
///
/// This class manages the state and events of a task, similar to UploadTask or DownloadTask.
/// It implements Future<TaskSnapshot> for asynchronous completion.
///
abstract class Task implements Future<TaskSnapshot> {
  TaskSnapshot _snapshot;
  final StreamController<TaskSnapshot> _controller;
  final FusabaseStorage storage;
  globals.LogLevel __logLevel;
  late final Future<void> _initFuture;
  Completer _completer;
  dynamic _helper;
  bool _uploadLoopActive;
  bool _uploadLoopRestartRequested;

  /// Constructs a new [Task] instance.
  ///
  /// Parameters:
  /// - [data]: The data for the task.
  /// - [storage]: The associated storage instance (required).
  /// - [ref]: The reference for the task (required).
  /// - [help]: The helper controller for the task.
  /// - [metadata]: Optional metadata for uploads.
  ///
  /// Returns: A new [Task] instance.
  ///
  /// Example:
  /// ```dart
  /// var task = Task(data: myData, storage: myStorage, ref: myRef, help: myHelper);
  /// ```
  Task({
    required dynamic data,
    required this.storage,
    required Reference ref,
    required dynamic help,
    SettableMetadata? metadata,
  }) : _controller = StreamController<TaskSnapshot>(),
       _snapshot = TaskSnapshot(storage, ref, metadata),
       _helper = help,
       __logLevel = storage.app.logLevel,
       _completer = Completer(),
       _uploadLoopActive = false,
       _uploadLoopRestartRequested = false;

  /// Gets the stream of task snapshots.
  ///
  /// Returns: A [Stream] of [TaskSnapshot] events.
  Stream<TaskSnapshot> get snapshotEvents => _controller.stream;

  /// Gets the current task snapshot.
  ///
  /// Returns: The current [TaskSnapshot].
  TaskSnapshot get snapshot => _snapshot;

  /// Returns a single-event stream that completes with the final snapshot.
  ///
  /// Returns a [Stream<TaskSnapshot>] for use with stream APIs.
  ///
  /// Example:
  /// ```dart
  /// await for (final snapshot in task.asStream()) {
  ///   print(snapshot.state);
  /// }
  /// ```
  @override
  Stream<TaskSnapshot> asStream() =>
      _completer.future.asStream().map((_) => _snapshot);

  /// Registers a completion callback, as required by [Future.then].
  ///
  /// [onValue] receives the final [TaskSnapshot]; [onError] handles a failure.
  /// Returns a [Future<S>] containing the callback result.
  ///
  /// Example:
  /// ```dart
  /// task.then((snapshot) => snapshot.bytesTransferred);
  /// ```
  @override
  Future<S> then<S>(
    FutureOr<S> Function(TaskSnapshot) onValue, {
    Function? onError,
  }) => _completer.future.then((_) {
    return onValue(snapshot);
  }, onError: onError);

  /// Registers an error handler, as required by [Future.catchError].
  ///
  /// [onError] handles task failures and [test] optionally filters errors.
  /// Returns a [Future<TaskSnapshot>] after completion.
  ///
  /// Example:
  /// ```dart
  /// await task.catchError((error) => throw error);
  /// ```
  @override
  Future<TaskSnapshot> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) async {
    await _completer.future.catchError(onError, test: test);
    return snapshot;
  }

  /// Runs [action] after the task completes, as required by [Future.whenComplete].
  ///
  /// Returns a [Future<TaskSnapshot>] after the action has run.
  ///
  /// Example:
  /// ```dart
  /// await task.whenComplete(() => print('transfer finished'));
  /// ```
  @override
  Future<TaskSnapshot> whenComplete(FutureOr Function() action) async {
    await _completer.future.whenComplete(action);
    return snapshot;
  }

  /// Applies a time limit to completion of the task.
  ///
  /// [timeLimit] ([Duration]) is the maximum wait time. [onTimeout] optionally
  /// supplies a snapshot when the limit expires.
  ///
  /// Returns a [Future<TaskSnapshot>] for the task result or timeout result.
  ///
  /// Example:
  /// ```dart
  /// await task.timeout(const Duration(minutes: 1));
  /// ```
  @override
  Future<TaskSnapshot> timeout(
    Duration timeLimit, {
    FutureOr<TaskSnapshot> Function()? onTimeout,
  }) => _completer.future
      .then((_) => snapshot)
      .timeout(timeLimit, onTimeout: onTimeout);

  /// @nodoc
  /// Fires a snapshot event.
  ///
  /// Parameters:
  /// - [snap]: The snapshot to fire.
  void __fireEvent(TaskSnapshot snap) {
    this._controller.add(snap);
  }

  /// @nodoc
  /// Changes the state of the task.
  ///
  /// Parameters:
  /// - [state]: The new [TaskState].
  ///
  /// Returns: A Future that completes when the state is changed.
  Future<void> __changeState(TaskState state) async {
    final isTerminalState =
        state == TaskState.success ||
        state == TaskState.canceled ||
        state == TaskState.error;
    if (isTerminalState && _completer.isCompleted) {
      return;
    }

    _snapshot.state = state;

    Map<String, dynamic> detail = Map<String, dynamic>();
    detail["snapshot"] = _snapshot;
    detail["error"] = null;

    Map<String, Map<String, dynamic>> options =
        Map<String, Map<String, dynamic>>();

    options["detail"] = detail;

    //fire event
    __fireEvent(_snapshot);

    switch (state) {
      case TaskState.success:
        if (!this._completer.isCompleted) {
          this._completer.complete(_snapshot);
        }
        break;
      case TaskState.canceled:
        FusabaseException err = FusabaseException(
          code: "499",
          message: StorageErrorMessages.UPLOAD_ABORTED,
          name: "FusabaseStorageError",
        );
        if (!this._completer.isCompleted) {
          this._completer.completeError(err);
        }
        break;
      case TaskState.error:
        FusabaseException err = FusabaseException(
          code: "501",
          message: StorageErrorMessages.UNKNOWN,
          name: "FusabaseStorageError",
        );
        if (!this._completer.isCompleted) {
          this._completer.completeError(err);
        }
        break;
      default:
    }
  }

  /// @nodoc
  Future<void> __failWithError(Object error, [StackTrace? stackTrace]) async {
    if (_completer.isCompleted) {
      return;
    }
    _snapshot.state = TaskState.error;
    __fireEvent(_snapshot);
    _completer.completeError(error, stackTrace);
  }

  /// Pauses the task.
  ///
  /// Returns: A Future that resolves to true if paused successfully.
  ///
  /// Example:
  /// ```dart
  /// final paused = await task.pause();
  /// ```
  Future<bool> pause() async {
    await _initFuture;
    if (_helper.runtimeType == DownloadTaskController) {
      return false;
    }
    if (this._snapshot.state == TaskState.success ||
        this._snapshot.state == TaskState.canceled ||
        this._snapshot.state == TaskState.error ||
        this._snapshot.state == TaskState.paused) {
      return false;
    }
    await __changeState(TaskState.paused);
    return true;
  }

  /// Cancels the task.
  ///
  /// Returns: A Future that resolves to true if canceled successfully.
  ///
  /// Example:
  /// ```dart
  /// final canceled = await task.cancel();
  /// ```
  Future<bool> cancel() async {
    await _initFuture;
    if (_helper.isMultipart == null) {
      return false;
    }
    if (this._snapshot.state == TaskState.success) {
      return false;
    }
    await this._helper.abortTask(createClient(storage.app), storage._config);

    await __changeState(TaskState.canceled);
    return true;
  }

  /// @nodoc
  Future<bool> __resumeUpload() async {
    if (this._snapshot.state != TaskState.running) {
      return false;
    }
    FusabaseAuth auth = FusabaseAuth.instanceFor(app: this.storage.app);
    String? accessToken = await getAccessToken(auth);
    bool result = false;
    try {
      dynamic res = await this._helper.continueTask(
        snapshot: _snapshot,
        config: storage._config,
        accessToken: accessToken,
      );
      _snapshot._bytesTransferred = res["bytesTransferred"];
      if (res["state"] == TaskState.success) {
        if (res["md5sum"] != null) {
          _snapshot.metadata?.__setMetaData("md5Hash", res["md5sum"]);
        }
        _snapshot.metadata?.__setMetaData("bucket", _snapshot.ref._bucket);
        _snapshot.metadata?.__setMetaData("size", _snapshot._totalBytes);
        _snapshot.metadata?.__setMetaData("timeCreated", res["timeCreated"]);
        _snapshot.metadata?.__setMetaData("updated", res["updated"]);
        _snapshot.metadata?.__setMetaData("contentType", res["contentType"]);
        await __changeState(res["state"]);
      } else if (res["state"] == TaskState.running) {
        result = true;
      }
    } catch (err, stackTrace) {
      if (err.toString() == "AbortError") {
        return false;
      }
      await __failWithError(err, stackTrace);
      return false;
    }
    return result;
  }

  /// @nodoc
  Future<void> __runUpload() async {
    // Only one upload loop may touch the shared multipart controller at a time.
    if (_uploadLoopActive) {
      _uploadLoopRestartRequested = true;
      return;
    }

    _uploadLoopActive = true;
    try {
      do {
        _uploadLoopRestartRequested = false;
        while (this._snapshot.state == TaskState.running &&
            !this._completer.isCompleted) {
          final shouldContinue = await this.__resumeUpload();
          if (!shouldContinue) {
            break;
          }
        }
      } while (_uploadLoopRestartRequested &&
          this._snapshot.state == TaskState.running &&
          !this._completer.isCompleted);
    } finally {
      final shouldRestart =
          _uploadLoopRestartRequested &&
          this._snapshot.state == TaskState.running &&
          !this._completer.isCompleted;
      _uploadLoopActive = false;
      _uploadLoopRestartRequested = false;
      if (shouldRestart) {
        this.__runUpload();
      }
    }
  }

  /// Resumes the task.
  ///
  /// Returns: A Future that resolves to true if resumed successfully.
  ///
  /// Example:
  /// ```dart
  /// final resumed = await task.resume();
  /// ```
  Future<bool> resume() async {
    await _initFuture;
    if (_helper.runtimeType == DownloadTaskController) {
      return false;
    }
    if (this._snapshot.state == TaskState.success ||
        this._snapshot.state == TaskState.canceled ||
        this.snapshot.state == TaskState.error ||
        this._snapshot.state == TaskState.running) {
      return false;
    }

    if (_helper is DownloadTaskController) {
      return false;
    }

    await __changeState(TaskState.running);

    this.__runUpload();

    return true;
  }
}

/// Snapshot of a task's progress.
///
/// This class provides a snapshot of the task's state, progress, and metadata.
///
class TaskSnapshot {
  int _bytesTransferred;
  FullMetadata? _metadata;
  Reference _ref;
  int _totalBytes;
  final FusabaseStorage storage;
  TaskState _state;

  /// Constructs a new [TaskSnapshot].
  ///
  /// Parameters:
  /// - [storage]: The associated storage instance.
  /// - [ref]: The reference for the task.
  /// - [metadata_g]: Optional settable metadata.
  ///
  /// Returns: A new [TaskSnapshot] instance.
  ///
  /// Example:
  /// ```dart
  /// var snapshot = TaskSnapshot(myStorage, myRef, myMetadata);
  /// ```
  TaskSnapshot(this.storage, Reference ref, SettableMetadata? metadata_g)
    : _bytesTransferred = 0,
      _totalBytes = 0,
      _ref = ref,
      _state = TaskState.running,
      this._metadata =
          metadata_g == null ? null : FullMetadata(metadata_g.asMap()) {
    this._metadata?.__setMetaData("fullPath", ref.fullPath);
    this._metadata?.__setMetaData("name", ref.name);
  }

  @override
  int get hashCode => Object.hash(storage, ref);

  /// Gets the metadata of the task.
  ///
  /// Returns: The [FullMetadata] or null.
  FullMetadata? get metadata => _metadata;

  /// Gets the number of bytes transferred.
  ///
  /// Returns: The bytes transferred integer.
  int get bytesTransferred {
    return _bytesTransferred;
  }

  /// Gets the total bytes of the task.
  ///
  /// Returns: The total bytes integer.
  int get totalBytes {
    return _totalBytes;
  }

  @override
  String toString() => '$TaskSnapshot(ref: $ref, state: $state)';

  @override
  bool operator ==(Object other) =>
      other is TaskSnapshot && other.ref == ref && other.storage == storage;

  /// Gets the reference for this snapshot.
  ///
  /// Returns: The [Reference].
  Reference get ref => _ref;

  /// Gets the current state of the task.
  ///
  /// Returns: The [TaskState].
  TaskState get state {
    return _state;
  }

  /// Sets the state of the task.
  set state(TaskState newState) {
    this._state = newState;
  }
}

/// Task for uploading data.
///
/// This class extends [Task] for handling uploads.
///
class UploadTask extends Task {
  SettableMetadata? _metadata;

  /// Constructs a new [UploadTask].
  ///
  /// Parameters:
  /// - [data]: The data to upload.
  /// - [storage]: The storage instance.
  /// - [metadata]: The metadata for the upload.
  /// - [ref]: The reference to upload to.
  ///
  /// Returns: A new [UploadTask] instance.
  ///
  /// Example:
  /// ```dart
  /// var uploadTask = UploadTask(myData, myStorage, myMetadata, myRef);
  /// ```
  UploadTask(
    dynamic data,
    FusabaseStorage storage,
    SettableMetadata? metadata,
    Reference ref,
  ) : this._metadata = metadata,
      super(
        data: data,
        storage: storage,
        ref: ref,
        help: UploadTaskController(
          metadata: metadata,
          app: storage.app,
          logLevel: storage.app.logLevel,
          chunkSize: storage.app.options.chunkSize,
          maxUploadSize: storage.app.options.maxUploadSize,
          retryTime: storage._maxUploadRetryTime,
        ),
        metadata: metadata,
      ) {
    super._initFuture = super._helper.initUpload(
      snapshot: super._snapshot,
      data: data,
      metadata: _metadata,
    );
    super._initFuture
        .then((x) {
          super.__runUpload();
        })
        .catchError((err, stacktrace) {
          super.__failWithError(err, stacktrace);
        });
  }
}

/// Task for downloading data.
///
/// This class extends [Task] for handling downloads.
///
/// Example:
/// ```dart
/// var downloadTask = DownloadTask(myFile, myStorage, myRef);
/// ```
class DownloadTask extends Task {
  /// Constructs a new [DownloadTask].
  ///
  /// Parameters:
  /// - [file]: The file to download to.
  /// - [storage]: The storage instance.
  /// - [ref]: The reference to download from.
  ///
  /// Returns: A new [DownloadTask] instance.
  DownloadTask(dynamic file, FusabaseStorage storage, Reference ref)
    : super(
        data: file,
        storage: storage,
        ref: ref,
        help: DownloadTaskController(
          app: storage.app,
          logLevel: storage.app.logLevel,
          retryTime: storage._maxDownloadRetryTime,
        ),
      ) {
    super._helper.initDownload(
      snapshot: super._snapshot,
      data: file,
      ref: ref,
      task: this,
      config: storage._config,
    );
    super.__changeState(TaskState.running);
  }

  /// Internal method to change state.
  ///
  /// Parameters:
  /// - [state]: The new state.
  ///
  /// Returns: A Future that completes when state is changed.
  Future<void> __makeStateChange(TaskState state) async {
    await super.__changeState(state);
  }
}
