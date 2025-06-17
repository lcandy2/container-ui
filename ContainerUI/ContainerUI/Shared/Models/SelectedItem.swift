//
//  SelectedItem.swift
//  ContainerUI
//
//  Created by 甜檸Citron(lcandy2) on 6/16/25.
//  Copyright © 2025 https://github.com/lcandy2. All Rights Reserved.
//

import Foundation
import ContainerModels

enum SelectedItem: Hashable {
    case container(Container)
    case image(ContainerImage)
    case system
}