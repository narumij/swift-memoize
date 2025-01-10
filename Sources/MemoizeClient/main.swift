import Memoize

@Memoized(maxCount:1000)
func tarai2(x: Int, y: Int, z: Int) -> Int {
  if x <= y {
    return y
  } else {
    return tarai2(
      x: tarai2(x: x - 1, y: y, z: z),
      y: tarai2(x: y - 1, y: z, z: x),
      z: tarai2(x: z - 1, y: x, z: y))
  }
}

tarai2_cache.removeAll()

print("Tak 20 10 0 is \(tarai2(x: 20, y: 10, z: 0))")

print(tarai2_cache.count)

class Fib {
  var one: Int { 1 }
  var two: Int { 2 }
  @Memoized(maxCount:150)
  func fibonacci(_ n: Int) -> Int {
      if n <= one { return n }
      return fibonacci(n - one) + fibonacci(n - two)
  }
}

let fib = Fib()

fib.fibonacci_cache.removeAll()

print(fib.fibonacci(40)) // Output: 102_334_155

print(fib.fibonacci_cache.count)

class Fib2 {
  static var one: Int { 1 }
  static var two: Int { 2 }
  @Memoized(maxCount:150)
  static func fibonacci(_ n: Int) -> Int {
      if n <= one { return n }
      return fibonacci(n - one) + fibonacci(n - two)
  }
}

Fib2.fibonacci_cache.removeAll()

print(Fib2.fibonacci(40)) // Output: 102_334_155

print(Fib2.fibonacci_cache.count)
