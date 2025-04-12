//
//  ISchema.swift
//  Observable
//
//  Created by no-today on 2024/5/27.
//

import Foundation
import SwiftData

public typealias CurrentScheme = SchemaV1

public enum SchemaV1: VersionedSchema {
  public static var versionIdentifier: Schema.Version {
    .init(1, 0, 0)
  }

  public static var models: [any PersistentModel.Type] {
      [
        Asset.self,
        AssetChangeLog.self
      ]
  }
}
