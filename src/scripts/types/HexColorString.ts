export type HexColorString = `#${string}`

export function isHexColorString(str: string): str is HexColorString {
  return str.length === 4 || (str.length === 7 && str[0] === '#')
}
