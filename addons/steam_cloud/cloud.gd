extends Node

signal save_finished
signal save_failed(is_remote)

signal loaded_with_conflicts(remote_data, local_data, filename)
signal load_finished(contents, filename)
signal load_failed(is_remote)

const DEFAULT_SAVE_PATH := "user://"

var last_local_resource: Resource
var cached_file_path: String = ""
var cached_file_name: String = ""


func _ready() -> void:
    Steam.connect("file_write_async_complete", self, "_on_file_write_async_completed")
    Steam.connect("file_read_async_complete", self, "_on_file_read_async_completed")

func save(_filename: String, _resource: Resource, _path: String = DEFAULT_SAVE_PATH) -> void:
    cached_file_path = _path
    cached_file_name = _filename
    Steam.beginFileWriteBatch()
    var _save_path: String = _path + _filename
    var _result: int = ResourceSaver.save(_save_path, _resource)

    if _result != OK:
        push_error("[Cloud.gd] Something fucked up")
        emit_signal("save_failed", false)
        Steam.endFileWriteBatch()
        return
    
    var _file := File.new()
    var _resource_contents: String
    _file.open(_save_path, File.READ)
    _resource_contents = _file.get_as_text()
    _file.close()
    Steam.fileWriteAsync(_filename, _resource_contents.to_utf8())


func _process(_delta: float) -> void:
    Steam.run_callbacks()


func _on_file_write_async_completed(_result: int) -> void:
    if _result != Steam.RESULT_OK:
        emit_signal("save_failed", true)
        push_error("[SteamCloud] Async Write Error %s. Check %s for further information." % [_result, "https://partner.steamgames.com/doc/api/steam_api#EResult"])
        return

    Steam.endFileWriteBatch()
    emit_signal("save_finished")


func _on_file_read_async_completed(_remote_file: Dictionary) -> void:
    var _file_contents: String
    var _resource: Resource

    if _remote_file.has("result") and _remote_file.result != Steam.RESULT_OK:
        var _result: int = _remote_file.result
        push_error("[SteamCloud] Async Read Error %s. Check %s for further information." % [_result, "https://partner.steamgames.com/doc/api/steam_api#EResult"])
        emit_signal("load_failed", true)
        return

    if _remote_file.has("buffer"):
        _file_contents = _remote_file.buffer.get_string_from_utf8()
        
    var _file := File.new()
    _file.open(cached_file_path + cached_file_name, File.WRITE)
    _file.store_string(_file_contents)
    _file.close()

    _resource = ResourceLoader.load(cached_file_path + cached_file_name)

    if not _file_contents.empty() and last_local_resource:
        emit_signal("loaded_with_conflicts", _resource, last_local_resource, cached_file_name)
        last_local_resource = null
        return
    elif not _file_contents.empty():
        emit_signal("load_finished", _resource, cached_file_name)
    elif last_local_resource:
        emit_signal("load_finished", last_local_resource, cached_file_name)


func load_local(_filename: String, _path: String = DEFAULT_SAVE_PATH) -> Resource:
    var _file := ResourceLoader.load(_path + _filename)
    return _file


func load_remote_async(_filename: String) -> void:
    Steam.fileReadAsync(_filename, 0, Steam.getFileSize(_filename))


func load(_filename: String, _path: String = DEFAULT_SAVE_PATH) -> void:
    var _local_resource := load_local(_filename, _path)
    last_local_resource = _local_resource
    cached_file_name = _filename
    cached_file_path = _path

    if Steam.fileExists(_filename):
        load_remote_async(_filename)
        return

    emit_signal("load_finished", last_local_resource.duplicate(), _filename)
    last_local_resource = null
