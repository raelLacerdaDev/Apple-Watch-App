//
//  AppRoute.swift
//  NavigationWatchOs
//
//  Created by israel lacerda gomes santos on 19/08/26.
//

enum AppRoute: Hashable {
    case ready(mode : SessionMode)
    case session
    case config
    case mode
    case gestureSession
}
