export const EVENT_PREFIX = "GAMEBUDDY_EVENT ";

export function parseEvents(output) {
  const events = [];
  const protocolErrors = [];

  for (const [index, line] of output.split(/\r?\n/).entries()) {
    const marker = line.indexOf(EVENT_PREFIX);
    if (marker === -1) continue;
    const json = line.slice(marker + EVENT_PREFIX.length).trim();
    try {
      const event = JSON.parse(json);
      if (!event || typeof event !== "object" || typeof event.type !== "string") {
        throw new Error("event must be an object with a string type");
      }
      events.push(event);
    } catch (error) {
      protocolErrors.push({ line: index + 1, message: error.message });
    }
  }

  return { events, protocolErrors };
}
