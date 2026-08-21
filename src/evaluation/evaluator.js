function readField(object, field) {
  return field.split(".").reduce((value, part) => value?.[part], object);
}

function compare(actual, operator, expected) {
  switch (operator) {
    case "exists": return true;
    case "==": return actual === expected;
    case "!=": return actual !== expected;
    case ">": return actual > expected;
    case ">=": return actual >= expected;
    case "<": return actual < expected;
    case "<=": return actual <= expected;
    case "includes": return Array.isArray(actual) || typeof actual === "string"
      ? actual.includes(expected)
      : false;
    default: return false;
  }
}

export function evaluateAssertions(assertions, events) {
  const results = assertions.map((assertion) => {
    const candidates = events.filter((event) => event.type === assertion.event);
    const operator = assertion.operator ?? "exists";
    const matched = candidates.some((event) => {
      if (operator === "exists") return true;
      return compare(readField(event, assertion.field), operator, assertion.value);
    });
    return {
      id: assertion.id,
      passed: matched,
      event: assertion.event,
      ...(matched ? {} : { reason: `no ${assertion.event} event satisfied ${operator}` }),
    };
  });

  const passed = results.filter((result) => result.passed).length;
  return {
    score: results.length === 0 ? 0 : passed / results.length,
    passed,
    total: results.length,
    results,
  };
}
