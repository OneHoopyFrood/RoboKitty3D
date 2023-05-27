export type Settings = {
  invertPitchControl: boolean
}

export class GameSettings {
  private _settings: Settings

  constructor() {
    this._settings = {
      // Default settings
      invertPitchControl: false,
    }
  }

  public load() {
    try {
      const settings = localStorage.getItem('settings')
      if (settings) {
        this._settings = {
          ...this._settings,
          // Override with any settings found in local storage
          ...JSON.parse(settings),
        }
      }
    } catch (error) {
      console.error('Error loading settings from local storage: ', error)
    }
  }

  public save() {
    localStorage.setItem('settings', JSON.stringify(this))
  }

  public onChange(settingKey: keyof GameSettings['_settings'], callback: (value: any) => void) {
    const handler = {
      set: (target: any, property: string, value: any) => {
        target[property] = value
        if (property === settingKey) callback(value)
        return value
      },
    }
    this._settings = new Proxy(this._settings, handler)
  }

  public set(settingKey: keyof GameSettings['_settings'], value: any) {
    this._settings[settingKey] = value
  }

  public get(settingKey: keyof GameSettings['_settings']) {
    return this._settings[settingKey]
  }
}
