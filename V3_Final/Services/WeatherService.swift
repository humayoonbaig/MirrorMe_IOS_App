import Foundation
import CoreLocation
import Combine

// MARK: - WeatherService
/// Fetches live weather using Open-Meteo (free, no API key) and reverse geocoding for city name.
class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = WeatherService()

    // Published weather data
    @Published var temperature: String = "--°"
    @Published var cityName: String = "—"
    @Published var weatherIcon: String = "cloud.sun.fill"
    @Published var conditionText: String = ""
    @Published var isCelsius: Bool = false

    // Location authorization state — observed by onboarding
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var hasResolvedLocation = false
    private var temperatureFahrenheit: Int?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func toggleUnit() {
        isCelsius.toggle()
        guard let f = temperatureFahrenheit else { return }
        temperature = isCelsius
            ? "\(Int(round(Double(f - 32) * 5.0 / 9.0)))°C"
            : "\(f)°F"
    }

    func fetchWeatherIfAuthorized() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else { return }
        hasResolvedLocation = false
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            hasResolvedLocation = false
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasResolvedLocation, let location = locations.last else { return }
        hasResolvedLocation = true

        // Reverse geocode for city name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let city = placemarks?.first?.locality,
               let country = placemarks?.first?.isoCountryCode {
                DispatchQueue.main.async {
                    self?.cityName = "\(city), \(country)"
                }
            }
        }

        // Fetch weather from Open-Meteo
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        fetchOpenMeteo(lat: lat, lon: lon)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle — widget stays at default
    }

    // MARK: - Open-Meteo API

    private func fetchOpenMeteo(lat: Double, lon: Double) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&temperature_unit=fahrenheit"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data, error == nil else { return }
            // Decode on background thread
            guard let response = try? JSONDecoder().decode(OpenMeteoResponse.self, from: data) else { return }
            let tempF = Int(response.current.temperature_2m)
            let code = response.current.weather_code
            let icon = Self.sfSymbol(for: code)
            let condition = Self.conditionText(for: code)
            DispatchQueue.main.async {
                self?.temperatureFahrenheit = tempF
                if self?.isCelsius == true {
                    let tempC = Int(round(Double(tempF - 32) * 5.0 / 9.0))
                    self?.temperature = "\(tempC)°C"
                } else {
                    self?.temperature = "\(tempF)°F"
                }
                self?.weatherIcon = icon
                self?.conditionText = condition
            }
        }.resume()
    }

    // MARK: - WMO Weather Code → SF Symbol

    static func sfSymbol(for code: Int) -> String {
        switch code {
        case 0:       return "sun.max.fill"
        case 1, 2:    return "cloud.sun.fill"
        case 3:       return "cloud.fill"
        case 45, 48:  return "cloud.fog.fill"
        case 51, 53, 55:           return "cloud.drizzle.fill"
        case 56, 57:               return "cloud.sleet.fill"
        case 61, 63, 65:           return "cloud.rain.fill"
        case 66, 67:               return "cloud.sleet.fill"
        case 71, 73, 75, 77:      return "cloud.snow.fill"
        case 80, 81, 82:          return "cloud.heavyrain.fill"
        case 85, 86:              return "cloud.snow.fill"
        case 95:                  return "cloud.bolt.fill"
        case 96, 99:              return "cloud.bolt.rain.fill"
        default:                  return "cloud.sun.fill"
        }
    }

    static func conditionText(for code: Int) -> String {
        switch code {
        case 0:       return "Clear sky"
        case 1:       return "Mainly clear"
        case 2:       return "Partly cloudy"
        case 3:       return "Overcast"
        case 45, 48:  return "Foggy"
        case 51, 53, 55:       return "Drizzle"
        case 56, 57:           return "Freezing drizzle"
        case 61, 63, 65:       return "Rain"
        case 66, 67:           return "Freezing rain"
        case 71, 73, 75, 77:  return "Snow"
        case 80, 81, 82:      return "Rain showers"
        case 85, 86:          return "Snow showers"
        case 95:              return "Thunderstorm"
        case 96, 99:          return "Thunderstorm with hail"
        default:              return ""
        }
    }
}

// MARK: - Open-Meteo JSON Model

private nonisolated struct OpenMeteoResponse: Decodable, Sendable {
    let current: CurrentWeather

    struct CurrentWeather: Decodable, Sendable {
        let temperature_2m: Double
        let weather_code: Int
    }
}
