from google.protobuf.internal import containers as _containers
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Metadata(_message.Message):
    __slots__ = ("title", "poster", "json")
    TITLE_FIELD_NUMBER: _ClassVar[int]
    POSTER_FIELD_NUMBER: _ClassVar[int]
    JSON_FIELD_NUMBER: _ClassVar[int]
    title: str
    poster: str
    json: str
    def __init__(self, title: _Optional[str] = ..., poster: _Optional[str] = ..., json: _Optional[str] = ...) -> None: ...

class Vod(_message.Message):
    __slots__ = ("id", "playlist_url", "url", "metadata", "created_at")
    ID_FIELD_NUMBER: _ClassVar[int]
    PLAYLIST_URL_FIELD_NUMBER: _ClassVar[int]
    URL_FIELD_NUMBER: _ClassVar[int]
    METADATA_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    id: int
    playlist_url: str
    url: str
    metadata: Metadata
    created_at: str
    def __init__(self, id: _Optional[int] = ..., playlist_url: _Optional[str] = ..., url: _Optional[str] = ..., metadata: _Optional[_Union[Metadata, _Mapping]] = ..., created_at: _Optional[str] = ...) -> None: ...

class CreateVodRequest(_message.Message):
    __slots__ = ("playlist_url", "metadata")
    PLAYLIST_URL_FIELD_NUMBER: _ClassVar[int]
    METADATA_FIELD_NUMBER: _ClassVar[int]
    playlist_url: str
    metadata: Metadata
    def __init__(self, playlist_url: _Optional[str] = ..., metadata: _Optional[_Union[Metadata, _Mapping]] = ...) -> None: ...

class CreateVodResponse(_message.Message):
    __slots__ = ("vod", "created")
    VOD_FIELD_NUMBER: _ClassVar[int]
    CREATED_FIELD_NUMBER: _ClassVar[int]
    vod: Vod
    created: bool
    def __init__(self, vod: _Optional[_Union[Vod, _Mapping]] = ..., created: _Optional[bool] = ...) -> None: ...

class GetVodRequest(_message.Message):
    __slots__ = ("id",)
    ID_FIELD_NUMBER: _ClassVar[int]
    id: int
    def __init__(self, id: _Optional[int] = ...) -> None: ...

class ListVodsRequest(_message.Message):
    __slots__ = ("limit", "after_id")
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    AFTER_ID_FIELD_NUMBER: _ClassVar[int]
    limit: int
    after_id: int
    def __init__(self, limit: _Optional[int] = ..., after_id: _Optional[int] = ...) -> None: ...

class ListVodsResponse(_message.Message):
    __slots__ = ("vods",)
    VODS_FIELD_NUMBER: _ClassVar[int]
    vods: _containers.RepeatedCompositeFieldContainer[Vod]
    def __init__(self, vods: _Optional[_Iterable[_Union[Vod, _Mapping]]] = ...) -> None: ...
