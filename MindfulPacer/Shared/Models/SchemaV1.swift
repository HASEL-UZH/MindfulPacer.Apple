//
//  SchemaV1.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 21.07.2024.
//

import SwiftData

public typealias CurrentScheme = SchemaV1

public enum SchemaV1: VersionedSchema {
  public static var versionIdentifier: Schema.Version {
    .init(1, 0, 0)
  }

  public static var models: [any PersistentModel.Type] {
      [HeartRateSample.self]
  }
}
