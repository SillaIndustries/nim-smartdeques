import deques
import locks
import options
import strformat
import os
import serialization
import strutils
import std/jsonutils
import std/[strtabs,json]

const MAX_LENGTH = 1000
const STORAGE_FILENAME = ".smartdeques"
const DEFAULT_PATH = "/tmp/"

type SmartDeques*[T] = object
    # sdLock: Lock
    queue: Deque[T]
    maxSize: int
    enableStorage: bool
    dirPathFile: string

# proc isStorageHealthy*(p: var SmartDeques): bool =
    # return fileExists(p.dirPathFile)

proc removeLastRecord(p: SmartDeques) = 
    var lines = readFile(p.dirPathFile).splitLines()
    if lines.len < 1:
        return
    lines = lines[0 .. ^3]
    let f = open(p.dirPathFile, fmWrite)
    defer: f.close()
    for line in lines:
        f.writeLine(line)

proc clearStorage(p: SmartDeques) =
    if not fileExists(p.dirPathFile):
        return
    writeFile(p.dirPathFile, "")

proc createStorageIfNotExists(p: SmartDeques) =
    if fileExists(p.dirPathFile):
        return
    writeFile(p.dirPathFile, "")

proc appendRecord(p: SmartDeques, line: string) =
    let f = open(p.dirPathFile, fmAppend)
    defer: f.close()
    f.writeLine(line)

proc push*[T](p: var SmartDeques[T], o: T): Option[T] {.gcsafe, discardable.} =
    # let hasLockAcquired = p.sdLock.tryAcquire()
    if p.queue.len >= p.maxSize:
        result = none(T)
    else:
        p.queue.addFirst(o)
        result = some(o)
        if p.enableStorage:
            p.appendRecord($o.toJson)
    # p.sdLock.release()

proc loadFromStorage[T](p: var SmartDeques[T]) =
    if not fileExists(p.dirPathFile):
        return
    var lines = readFile(p.dirPathFile).splitLines()
    for line in lines:
        if line.strip() == "":
            continue
        var elem: T
        fromJson(elem, parseJson(line))
        if not p.isFull:
            p.queue.addLast(elem)

proc clear*(p: var SmartDeques) =
    p.queue.clear()
    p.clearStorage()
    # if p.enableStorage:
        # p.initStorage()
    
proc newSmartDeque*[T](maxSize: uint = MAX_LENGTH, dirPathStorage: string = ""): SmartDeques[T] =
    var p: SmartDeques[T]
    p.maxSize = MAX_LENGTH
    if maxSize > 0:
        p.maxSize = (int)maxSize
    p.queue = initDeque[T](p.maxSize)
    # p.sdLock.initLock()
    p.dirPathFile = DEFAULT_PATH & STORAGE_FILENAME
    if not dirPathStorage.isEmptyOrWhitespace:
        p.dirPathFile = dirPathStorage
    return p

proc initStorage*(p: var SmartDeques) =
    p.enableStorage = true
    p.createStorageIfNotExists()
    p.loadFromStorage()

proc pop*[T](p: var SmartDeques[T]): Option[T] {.gcsafe.} =
    # let hasLockAcquired = p.sdLock.tryAcquire()
    # if not hasLockAcquired:
        # result = none(T)
    if p.hasElement:
        try:
            result = some(p.queue.popLast())
            if p.enableStorage:
                p.removeLastRecord()
        except RangeDefect: # manage timing when thread has not sleep
            result = none(T)
    else:
        result = none(T)
    # p.sdLock.release()

proc hasElement*(p: var SmartDeques): bool {.gcsafe.} =
    return p.queue.len > 0

proc peek*[T](p: var SmartDeques[T]): Option[T] {.gcsafe.} =
    return if p.hasElement: some(p.queue.peekLast) else: none(T)

proc isEmpty*(p: var SmartDeques): bool {.gcsafe.} =
    return p.queue.len == 0

proc isFull*(p: var SmartDeques): bool {.gcsafe.} =
    return p.queue.len >= p.maxSize

proc len*(p: var SmartDeques): int {.gcsafe.} =
    return p.queue.len

proc `$`*(p: var SmartDeques): string =
    var coll: seq[string]
    for el in p.queue.items:
        coll.add($el.toJson)
    return $coll

proc maxSize(p: var SmartDeques): int =
    return p.maxSize