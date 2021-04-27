//  This file was automatically generated and should not be edited.

import AWSAppSync

public struct CreateGlacierUsersInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
    graphQLMap = ["organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName]
  }

  public var organization: String {
    get {
      return graphQLMap["organization"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "organization")
    }
  }

  public var username: String {
    get {
      return graphQLMap["username"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: String? {
    get {
      return graphQLMap["email"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var extensionVoiceserver: String? {
    get {
      return graphQLMap["extension_voiceserver"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "extension_voiceserver")
    }
  }

  public var firstName: String? {
    get {
      return graphQLMap["first_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "first_name")
    }
  }

  public var glacierpwd: String? {
    get {
      return graphQLMap["glacierpwd"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "glacierpwd")
    }
  }

  public var lastName: String? {
    get {
      return graphQLMap["last_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "last_name")
    }
  }

  public var messengerId: String? {
    get {
      return graphQLMap["messenger_id"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messenger_id")
    }
  }

  public var userName: String? {
    get {
      return graphQLMap["user_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "user_name")
    }
  }
}

public struct UpdateGlacierUsersInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
    graphQLMap = ["organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName]
  }

  public var organization: String {
    get {
      return graphQLMap["organization"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "organization")
    }
  }

  public var username: String {
    get {
      return graphQLMap["username"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: String? {
    get {
      return graphQLMap["email"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var extensionVoiceserver: String? {
    get {
      return graphQLMap["extension_voiceserver"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "extension_voiceserver")
    }
  }

  public var firstName: String? {
    get {
      return graphQLMap["first_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "first_name")
    }
  }

  public var glacierpwd: String? {
    get {
      return graphQLMap["glacierpwd"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "glacierpwd")
    }
  }

  public var lastName: String? {
    get {
      return graphQLMap["last_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "last_name")
    }
  }

  public var messengerId: String? {
    get {
      return graphQLMap["messenger_id"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messenger_id")
    }
  }

  public var userName: String? {
    get {
      return graphQLMap["user_name"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "user_name")
    }
  }
}

public struct DeleteGlacierUsersInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(organization: String, username: String) {
    graphQLMap = ["organization": organization, "username": username]
  }

  public var organization: String {
    get {
      return graphQLMap["organization"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "organization")
    }
  }

  public var username: String {
    get {
      return graphQLMap["username"] as! String
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }
}

public struct TableGlacierUsersFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(organization: TableStringFilterInput? = nil, username: TableStringFilterInput? = nil, email: TableStringFilterInput? = nil, extensionVoiceserver: TableStringFilterInput? = nil, firstName: TableStringFilterInput? = nil, glacierpwd: TableStringFilterInput? = nil, lastName: TableStringFilterInput? = nil, messengerId: TableStringFilterInput? = nil, userName: TableStringFilterInput? = nil) {
    graphQLMap = ["organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName]
  }

  public var organization: TableStringFilterInput? {
    get {
      return graphQLMap["organization"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "organization")
    }
  }

  public var username: TableStringFilterInput? {
    get {
      return graphQLMap["username"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "username")
    }
  }

  public var email: TableStringFilterInput? {
    get {
      return graphQLMap["email"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "email")
    }
  }

  public var extensionVoiceserver: TableStringFilterInput? {
    get {
      return graphQLMap["extension_voiceserver"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "extension_voiceserver")
    }
  }

  public var firstName: TableStringFilterInput? {
    get {
      return graphQLMap["first_name"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "first_name")
    }
  }

  public var glacierpwd: TableStringFilterInput? {
    get {
      return graphQLMap["glacierpwd"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "glacierpwd")
    }
  }

  public var lastName: TableStringFilterInput? {
    get {
      return graphQLMap["last_name"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "last_name")
    }
  }

  public var messengerId: TableStringFilterInput? {
    get {
      return graphQLMap["messenger_id"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "messenger_id")
    }
  }

  public var userName: TableStringFilterInput? {
    get {
      return graphQLMap["user_name"] as! TableStringFilterInput?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "user_name")
    }
  }
}

public struct TableStringFilterInput: GraphQLMapConvertible {
  public var graphQLMap: GraphQLMap

  public init(ne: String? = nil, eq: String? = nil, le: String? = nil, lt: String? = nil, ge: String? = nil, gt: String? = nil, contains: String? = nil, notContains: String? = nil, between: [String?]? = nil, beginsWith: String? = nil) {
    graphQLMap = ["ne": ne, "eq": eq, "le": le, "lt": lt, "ge": ge, "gt": gt, "contains": contains, "notContains": notContains, "between": between, "beginsWith": beginsWith]
  }

  public var ne: String? {
    get {
      return graphQLMap["ne"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ne")
    }
  }

  public var eq: String? {
    get {
      return graphQLMap["eq"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "eq")
    }
  }

  public var le: String? {
    get {
      return graphQLMap["le"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "le")
    }
  }

  public var lt: String? {
    get {
      return graphQLMap["lt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "lt")
    }
  }

  public var ge: String? {
    get {
      return graphQLMap["ge"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "ge")
    }
  }

  public var gt: String? {
    get {
      return graphQLMap["gt"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "gt")
    }
  }

  public var contains: String? {
    get {
      return graphQLMap["contains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "contains")
    }
  }

  public var notContains: String? {
    get {
      return graphQLMap["notContains"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "notContains")
    }
  }

  public var between: [String?]? {
    get {
      return graphQLMap["between"] as! [String?]?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "between")
    }
  }

  public var beginsWith: String? {
    get {
      return graphQLMap["beginsWith"] as! String?
    }
    set {
      graphQLMap.updateValue(newValue, forKey: "beginsWith")
    }
  }
}

public final class CreateGlacierUsersMutation: GraphQLMutation {
  public static let operationString =
    "mutation CreateGlacierUsers($input: CreateGlacierUsersInput!) {\n  createGlacierUsers(input: $input) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var input: CreateGlacierUsersInput

  public init(input: CreateGlacierUsersInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("createGlacierUsers", arguments: ["input": GraphQLVariable("input")], type: .object(CreateGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(createGlacierUsers: CreateGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "createGlacierUsers": createGlacierUsers.flatMap { $0.snapshot }])
    }

    public var createGlacierUsers: CreateGlacierUser? {
      get {
        return (snapshot["createGlacierUsers"] as? Snapshot).flatMap { CreateGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "createGlacierUsers")
      }
    }

    public struct CreateGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class UpdateGlacierUsersMutation: GraphQLMutation {
  public static let operationString =
    "mutation UpdateGlacierUsers($input: UpdateGlacierUsersInput!) {\n  updateGlacierUsers(input: $input) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var input: UpdateGlacierUsersInput

  public init(input: UpdateGlacierUsersInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("updateGlacierUsers", arguments: ["input": GraphQLVariable("input")], type: .object(UpdateGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(updateGlacierUsers: UpdateGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "updateGlacierUsers": updateGlacierUsers.flatMap { $0.snapshot }])
    }

    public var updateGlacierUsers: UpdateGlacierUser? {
      get {
        return (snapshot["updateGlacierUsers"] as? Snapshot).flatMap { UpdateGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "updateGlacierUsers")
      }
    }

    public struct UpdateGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class DeleteGlacierUsersMutation: GraphQLMutation {
  public static let operationString =
    "mutation DeleteGlacierUsers($input: DeleteGlacierUsersInput!) {\n  deleteGlacierUsers(input: $input) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var input: DeleteGlacierUsersInput

  public init(input: DeleteGlacierUsersInput) {
    self.input = input
  }

  public var variables: GraphQLMap? {
    return ["input": input]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Mutation"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("deleteGlacierUsers", arguments: ["input": GraphQLVariable("input")], type: .object(DeleteGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(deleteGlacierUsers: DeleteGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Mutation", "deleteGlacierUsers": deleteGlacierUsers.flatMap { $0.snapshot }])
    }

    public var deleteGlacierUsers: DeleteGlacierUser? {
      get {
        return (snapshot["deleteGlacierUsers"] as? Snapshot).flatMap { DeleteGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "deleteGlacierUsers")
      }
    }

    public struct DeleteGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class GetGlacierUsersQuery: GraphQLQuery {
  public static let operationString =
    "query GetGlacierUsers($organization: String!, $username: String!) {\n  getGlacierUsers(organization: $organization, username: $username) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var organization: String
  public var username: String

  public init(organization: String, username: String) {
    self.organization = organization
    self.username = username
  }

  public var variables: GraphQLMap? {
    return ["organization": organization, "username": username]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("getGlacierUsers", arguments: ["organization": GraphQLVariable("organization"), "username": GraphQLVariable("username")], type: .object(GetGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(getGlacierUsers: GetGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "getGlacierUsers": getGlacierUsers.flatMap { $0.snapshot }])
    }

    public var getGlacierUsers: GetGlacierUser? {
      get {
        return (snapshot["getGlacierUsers"] as? Snapshot).flatMap { GetGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "getGlacierUsers")
      }
    }

    public struct GetGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class ListGlacierUsersQuery: GraphQLQuery {
  public static let operationString =
    "query ListGlacierUsers($filter: TableGlacierUsersFilterInput, $limit: Int, $nextToken: String) {\n  listGlacierUsers(filter: $filter, limit: $limit, nextToken: $nextToken) {\n    __typename\n    items {\n      __typename\n      organization\n      username\n      email\n      extension_voiceserver\n      first_name\n      glacierpwd\n      last_name\n      messenger_id\n      user_name\n    }\n    nextToken\n  }\n}"

  public var filter: TableGlacierUsersFilterInput?
  public var limit: Int?
  public var nextToken: String?

  public init(filter: TableGlacierUsersFilterInput? = nil, limit: Int? = nil, nextToken: String? = nil) {
    self.filter = filter
    self.limit = limit
    self.nextToken = nextToken
  }

  public var variables: GraphQLMap? {
    return ["filter": filter, "limit": limit, "nextToken": nextToken]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Query"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("listGlacierUsers", arguments: ["filter": GraphQLVariable("filter"), "limit": GraphQLVariable("limit"), "nextToken": GraphQLVariable("nextToken")], type: .object(ListGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(listGlacierUsers: ListGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Query", "listGlacierUsers": listGlacierUsers.flatMap { $0.snapshot }])
    }

    public var listGlacierUsers: ListGlacierUser? {
      get {
        return (snapshot["listGlacierUsers"] as? Snapshot).flatMap { ListGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "listGlacierUsers")
      }
    }

    public struct ListGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsersConnection"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("items", type: .list(.object(Item.selections))),
        GraphQLField("nextToken", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(items: [Item?]? = nil, nextToken: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsersConnection", "items": items.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, "nextToken": nextToken])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var items: [Item?]? {
        get {
          return (snapshot["items"] as? [Snapshot?]).flatMap { $0.map { $0.flatMap { Item(snapshot: $0) } } }
        }
        set {
          snapshot.updateValue(newValue.flatMap { $0.map { $0.flatMap { $0.snapshot } } }, forKey: "items")
        }
      }

      public var nextToken: String? {
        get {
          return snapshot["nextToken"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "nextToken")
        }
      }

      public struct Item: GraphQLSelectionSet {
        public static let possibleTypes = ["GlacierUsers"]

        public static let selections: [GraphQLSelection] = [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("organization", type: .nonNull(.scalar(String.self))),
          GraphQLField("username", type: .nonNull(.scalar(String.self))),
          GraphQLField("email", type: .scalar(String.self)),
          GraphQLField("extension_voiceserver", type: .scalar(String.self)),
          GraphQLField("first_name", type: .scalar(String.self)),
          GraphQLField("glacierpwd", type: .scalar(String.self)),
          GraphQLField("last_name", type: .scalar(String.self)),
          GraphQLField("messenger_id", type: .scalar(String.self)),
          GraphQLField("user_name", type: .scalar(String.self)),
        ]

        public var snapshot: Snapshot

        public init(snapshot: Snapshot) {
          self.snapshot = snapshot
        }

        public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
          self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
        }

        public var __typename: String {
          get {
            return snapshot["__typename"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "__typename")
          }
        }

        public var organization: String {
          get {
            return snapshot["organization"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "organization")
          }
        }

        public var username: String {
          get {
            return snapshot["username"]! as! String
          }
          set {
            snapshot.updateValue(newValue, forKey: "username")
          }
        }

        public var email: String? {
          get {
            return snapshot["email"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "email")
          }
        }

        public var extensionVoiceserver: String? {
          get {
            return snapshot["extension_voiceserver"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "extension_voiceserver")
          }
        }

        public var firstName: String? {
          get {
            return snapshot["first_name"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "first_name")
          }
        }

        public var glacierpwd: String? {
          get {
            return snapshot["glacierpwd"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "glacierpwd")
          }
        }

        public var lastName: String? {
          get {
            return snapshot["last_name"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "last_name")
          }
        }

        public var messengerId: String? {
          get {
            return snapshot["messenger_id"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "messenger_id")
          }
        }

        public var userName: String? {
          get {
            return snapshot["user_name"] as? String
          }
          set {
            snapshot.updateValue(newValue, forKey: "user_name")
          }
        }
      }
    }
  }
}

public final class OnCreateGlacierUsersSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnCreateGlacierUsers($organization: String, $username: String, $email: String, $extension_voiceserver: String, $first_name: String) {\n  onCreateGlacierUsers(organization: $organization, username: $username, email: $email, extension_voiceserver: $extension_voiceserver, first_name: $first_name) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var organization: String?
  public var username: String?
  public var email: String?
  public var extension_voiceserver: String?
  public var first_name: String?

  public init(organization: String? = nil, username: String? = nil, email: String? = nil, extension_voiceserver: String? = nil, first_name: String? = nil) {
    self.organization = organization
    self.username = username
    self.email = email
    self.extension_voiceserver = extension_voiceserver
    self.first_name = first_name
  }

  public var variables: GraphQLMap? {
    return ["organization": organization, "username": username, "email": email, "extension_voiceserver": extension_voiceserver, "first_name": first_name]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onCreateGlacierUsers", arguments: ["organization": GraphQLVariable("organization"), "username": GraphQLVariable("username"), "email": GraphQLVariable("email"), "extension_voiceserver": GraphQLVariable("extension_voiceserver"), "first_name": GraphQLVariable("first_name")], type: .object(OnCreateGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onCreateGlacierUsers: OnCreateGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onCreateGlacierUsers": onCreateGlacierUsers.flatMap { $0.snapshot }])
    }

    public var onCreateGlacierUsers: OnCreateGlacierUser? {
      get {
        return (snapshot["onCreateGlacierUsers"] as? Snapshot).flatMap { OnCreateGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onCreateGlacierUsers")
      }
    }

    public struct OnCreateGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class OnUpdateGlacierUsersSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnUpdateGlacierUsers($organization: String, $username: String, $email: String, $extension_voiceserver: String, $first_name: String) {\n  onUpdateGlacierUsers(organization: $organization, username: $username, email: $email, extension_voiceserver: $extension_voiceserver, first_name: $first_name) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var organization: String?
  public var username: String?
  public var email: String?
  public var extension_voiceserver: String?
  public var first_name: String?

  public init(organization: String? = nil, username: String? = nil, email: String? = nil, extension_voiceserver: String? = nil, first_name: String? = nil) {
    self.organization = organization
    self.username = username
    self.email = email
    self.extension_voiceserver = extension_voiceserver
    self.first_name = first_name
  }

  public var variables: GraphQLMap? {
    return ["organization": organization, "username": username, "email": email, "extension_voiceserver": extension_voiceserver, "first_name": first_name]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onUpdateGlacierUsers", arguments: ["organization": GraphQLVariable("organization"), "username": GraphQLVariable("username"), "email": GraphQLVariable("email"), "extension_voiceserver": GraphQLVariable("extension_voiceserver"), "first_name": GraphQLVariable("first_name")], type: .object(OnUpdateGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onUpdateGlacierUsers: OnUpdateGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onUpdateGlacierUsers": onUpdateGlacierUsers.flatMap { $0.snapshot }])
    }

    public var onUpdateGlacierUsers: OnUpdateGlacierUser? {
      get {
        return (snapshot["onUpdateGlacierUsers"] as? Snapshot).flatMap { OnUpdateGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onUpdateGlacierUsers")
      }
    }

    public struct OnUpdateGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}

public final class OnDeleteGlacierUsersSubscription: GraphQLSubscription {
  public static let operationString =
    "subscription OnDeleteGlacierUsers($organization: String, $username: String, $email: String, $extension_voiceserver: String, $first_name: String) {\n  onDeleteGlacierUsers(organization: $organization, username: $username, email: $email, extension_voiceserver: $extension_voiceserver, first_name: $first_name) {\n    __typename\n    organization\n    username\n    email\n    extension_voiceserver\n    first_name\n    glacierpwd\n    last_name\n    messenger_id\n    user_name\n  }\n}"

  public var organization: String?
  public var username: String?
  public var email: String?
  public var extension_voiceserver: String?
  public var first_name: String?

  public init(organization: String? = nil, username: String? = nil, email: String? = nil, extension_voiceserver: String? = nil, first_name: String? = nil) {
    self.organization = organization
    self.username = username
    self.email = email
    self.extension_voiceserver = extension_voiceserver
    self.first_name = first_name
  }

  public var variables: GraphQLMap? {
    return ["organization": organization, "username": username, "email": email, "extension_voiceserver": extension_voiceserver, "first_name": first_name]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes = ["Subscription"]

    public static let selections: [GraphQLSelection] = [
      GraphQLField("onDeleteGlacierUsers", arguments: ["organization": GraphQLVariable("organization"), "username": GraphQLVariable("username"), "email": GraphQLVariable("email"), "extension_voiceserver": GraphQLVariable("extension_voiceserver"), "first_name": GraphQLVariable("first_name")], type: .object(OnDeleteGlacierUser.selections)),
    ]

    public var snapshot: Snapshot

    public init(snapshot: Snapshot) {
      self.snapshot = snapshot
    }

    public init(onDeleteGlacierUsers: OnDeleteGlacierUser? = nil) {
      self.init(snapshot: ["__typename": "Subscription", "onDeleteGlacierUsers": onDeleteGlacierUsers.flatMap { $0.snapshot }])
    }

    public var onDeleteGlacierUsers: OnDeleteGlacierUser? {
      get {
        return (snapshot["onDeleteGlacierUsers"] as? Snapshot).flatMap { OnDeleteGlacierUser(snapshot: $0) }
      }
      set {
        snapshot.updateValue(newValue?.snapshot, forKey: "onDeleteGlacierUsers")
      }
    }

    public struct OnDeleteGlacierUser: GraphQLSelectionSet {
      public static let possibleTypes = ["GlacierUsers"]

      public static let selections: [GraphQLSelection] = [
        GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
        GraphQLField("organization", type: .nonNull(.scalar(String.self))),
        GraphQLField("username", type: .nonNull(.scalar(String.self))),
        GraphQLField("email", type: .scalar(String.self)),
        GraphQLField("extension_voiceserver", type: .scalar(String.self)),
        GraphQLField("first_name", type: .scalar(String.self)),
        GraphQLField("glacierpwd", type: .scalar(String.self)),
        GraphQLField("last_name", type: .scalar(String.self)),
        GraphQLField("messenger_id", type: .scalar(String.self)),
        GraphQLField("user_name", type: .scalar(String.self)),
      ]

      public var snapshot: Snapshot

      public init(snapshot: Snapshot) {
        self.snapshot = snapshot
      }

      public init(organization: String, username: String, email: String? = nil, extensionVoiceserver: String? = nil, firstName: String? = nil, glacierpwd: String? = nil, lastName: String? = nil, messengerId: String? = nil, userName: String? = nil) {
        self.init(snapshot: ["__typename": "GlacierUsers", "organization": organization, "username": username, "email": email, "extension_voiceserver": extensionVoiceserver, "first_name": firstName, "glacierpwd": glacierpwd, "last_name": lastName, "messenger_id": messengerId, "user_name": userName])
      }

      public var __typename: String {
        get {
          return snapshot["__typename"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "__typename")
        }
      }

      public var organization: String {
        get {
          return snapshot["organization"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "organization")
        }
      }

      public var username: String {
        get {
          return snapshot["username"]! as! String
        }
        set {
          snapshot.updateValue(newValue, forKey: "username")
        }
      }

      public var email: String? {
        get {
          return snapshot["email"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "email")
        }
      }

      public var extensionVoiceserver: String? {
        get {
          return snapshot["extension_voiceserver"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "extension_voiceserver")
        }
      }

      public var firstName: String? {
        get {
          return snapshot["first_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "first_name")
        }
      }

      public var glacierpwd: String? {
        get {
          return snapshot["glacierpwd"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "glacierpwd")
        }
      }

      public var lastName: String? {
        get {
          return snapshot["last_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "last_name")
        }
      }

      public var messengerId: String? {
        get {
          return snapshot["messenger_id"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "messenger_id")
        }
      }

      public var userName: String? {
        get {
          return snapshot["user_name"] as? String
        }
        set {
          snapshot.updateValue(newValue, forKey: "user_name")
        }
      }
    }
  }
}