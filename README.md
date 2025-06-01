# OpenSkyTrack
The OpenSky Network API to show planes on the map.

### How it works
- The project can be run without requiring any configuration.
- When the application is opened, a starting location appears on the map and the live flight data there is shown.
- The user can go anywhere on the map, zoom in or out. Flight data for the currently visible part of the map is displayed.
- By clicking the button at the top, the user can select the country they want and view the flights there.
- If the user does not change the visible area on the map for 5 seconds, the flight data is automatically refreshed.

### Include
- MVVM architecture
- Singleton Pattern
- Unit Tests 
- Integration Tests
- Network Layer
- Network Logger
- Programmatic UI Development
- Protocol-Oriented Programming
- Reactive Programming (RxSwift)
- Dependency Injection
- Generic Programming
- Error Handling
- Memory Management

- Note: Test Coverage Rate : %96

### Example Request
https://opensky-network.org/api/states/all?lamin=45.8389&lomin=5.9962&lamax=47.8229&lomax=10.5226

### Example Response
```
{
  "time": 1748457533,
  "states": [
    [
      "4400ec",
      "EJU12AL ",
      "Austria",
      1748457532,
      1748457532,
      6.6009,
      47.3525,
      6644.64,
      false,
      198.28,
      224.05,
      6.83,
      null,
      6896.1,
      "6740",
      false,
      0
    ],
    [
      "407b8e",
      "BAW425 ",
      "United Kingdom",
      1748457532,
      1748457533,
      7.5549,
      45.9639,
      11590.02,
      false,
      178.26,
      314.3,
      0.33,
      null,
      11864.34,
      "5766",
      false,
      0
    ],
    [
      "3cf19d",
      "VJH365 ",
      "Germany",
      1748457532,
      1748457532,
      8.5518,
      47.5401,
      7307.58,
      false,
      190.81,
      355.98,
      -7.48,
      null,
      7482.84,
      "1000",
      false,
      0
    ]
  ]
}
```

