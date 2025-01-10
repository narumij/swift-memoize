import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
@_spi(Testing) import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

public struct MemoizeMacro: BodyMacro & PeerMacro {

  public static func expansion(
    of node: AttributeSyntax,
    providingPeersOf declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      return []
    }
    
    let isStatic = isStaticFunction(funcDecl)
    let static_modifier = isStatic ? "static" + " " : ""
    
    return [
      """
      nonisolated(unsafe) \(raw: static_modifier)var \(cacheName(funcDecl)): [\(paramsType(funcDecl)): \(returnType(funcDecl))] = [:]
      """,
      """
      \(parametersValue(paramsType(funcDecl), funcDecl.signature.parameterClause))
      """,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {

    guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
      return []
    }

    var limit: String?
    let arguments = node.arguments?.as(LabeledExprListSyntax.self) ?? []
    for argument in arguments {
      if let label = argument.label?.text, label == "maxCount" {
        if let valueExpr = argument.expression.as(IntegerLiteralExprSyntax.self) {
          limit = valueExpr.literal.text
          break
        }
      }
    }

    return [
      """
      let maxCount: Int? = \(raw: limit ?? "nil")
      \(functionBody(paramsType(funcDecl).description,cacheName(funcDecl).text, "maxCount", funcDecl))
      """
    ]
  }
}

func functionBody(
  _ parameters: String, _ storage: String, _ maxCount: String, _ funcDecl: FunctionDeclSyntax
) -> CodeBlockItemSyntax {
  let params = funcDecl.signature.parameterClause.parameters.map {
    switch ($0.firstName.tokenKind, $0.firstName, $0.parameterName) {
    case (.wildcard, _, .some(let parameterName)):
      return "\(parameterName)"
    case (_, let firstName, .some(let parameterName)):
      return "\(firstName.trimmed): \(parameterName)"
    case (_, _, .none):
      fatalError()
    }
  }.joined(separator: ", ")
  return """
    func \(funcDecl.name)\(funcDecl.signature){
      let args = \(raw: parameters)(\(raw: params))
      if let result = \(raw: storage)[args] {
        return result
      }
      let r = body(\(raw: params))
      if let \(raw: maxCount), \(raw: storage).count == \(raw: maxCount) {
        \(raw: storage).remove(at: \(raw: storage).indices.randomElement()!)
      }
      \(raw: storage)[args] = r
      return r
    }
    func body\(funcDecl.signature)\(funcDecl.body)
    return \(raw: funcDecl.name)(\(raw: params))
    """
}

func parametersValue(_ name: TypeSyntax, _ parameterClause: FunctionParameterClauseSyntax)
  -> CodeBlockItemSyntax
{

  let inits = parameterClause.parameters.map {
    switch ($0.firstName.tokenKind, $0.firstName, $0.parameterName) {
    case (.wildcard, _, .some(let parameterName)):
      return "self.\(parameterName) = \(parameterName)"
    case (_, let firstName, .some(let parameterName)):
      return "self.\(firstName.trimmed) = \(parameterName)"
    case (_, _, .none):
      fatalError()
    }
  }.joined(separator: "\n")

  let members = parameterClause.parameters.map {
    switch ($0.firstName.tokenKind, $0.firstName, $0.parameterName, $0.type) {
    case (.wildcard, _, .some(let parameterName), let type):
      return "let \(parameterName): \(type)"
    case (_, let firstName, _, let type):
      return "let \(firstName.trimmed): \(type)"
    }
  }.joined(separator: "\n")

  return """
    struct \(name): Hashable {
      init\(parameterClause){
        \(raw: inits)
      }
      \(raw: members)
    }
    """
}

func cacheName(_ funcDecl: FunctionDeclSyntax) -> TokenSyntax {
  "\(raw: funcDecl.name.text)_cache"
}

func paramsType(_ funcDecl: FunctionDeclSyntax) -> TypeSyntax {
  "\(raw: funcDecl.name.text)_parameters"
}

func returnType(_ funcDecl: FunctionDeclSyntax) -> TypeSyntax {
  funcDecl.signature.returnClause?.type.trimmed ?? "Void"
}

func isStaticFunction(_ functionDecl: FunctionDeclSyntax) -> Bool {
  // 修飾子 (modifiers) を確認
  for modifier in functionDecl.modifiers {
    if modifier.name.text == "static" {
      return true
    }
  }
  return false
}

func isGlobalScope(functionDecl: FunctionDeclSyntax) -> Bool {
    // 親ノードをたどって確認
    var parent = functionDecl.parent
    while let current = parent {
        if current.is(SourceFileSyntax.self) {
            // 親が SourceFileSyntax ならグローバルスコープ
            return true
        }
        // 親ノードをたどる
        parent = current.parent
    }
    return false
}

@main
struct MemoizePlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    MemoizeMacro.self,
  ]
}
