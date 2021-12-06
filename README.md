## Introduction

An Swift database library built over [Google's LevelDB](http://code.google.com/p/leveldb), a fast embedded key-value store written by Google.

## Installation

By far, the easiest way to integrate this library in your project is by using [CocoaPods][1].

1. Have [Cocoapods][1] installed, if you don't already
2. In your Podfile, add the line 

        pod 'SwiftLevelDB'

3. Run `pod install`
4. Make something awesome.

## How to use

#### Open database

```Swift
 let db = LevelDB.open(db: "test.db")
```

#### Cache data

```Swift
db.putCodable(true, forKey: "bool")
```

#### Get data

```Swift
let getData = db.getCodable(forKey: "bool", type: Bool.self) ?? false
```


#### Delete data

```Swift
 db.delte("bool")
```


#### Keys

```Swift
 let keys: [Slice] = db.keys()
```

#### Close database

```Swift 
  db.close()
```


## License

Distributed under the [MIT license](LICENSE)

[1]: http://cocoapods.org
[2]: http://leveldb.googlecode.com/svn/trunk/doc/index.html



