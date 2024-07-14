//
//  MessageListController.swift
//  IOS-WhatsAppClone
//
//  Created by Đoàn Văn Khoan on 4/7/24.
//

import Foundation
import UIKit
import SwiftUI
import Combine

/// A UITableView in UIKit is a view used in iOS development for displaying a list of data in a scrollable, single-column format. It is a powerful and flexible way to present data in a structured manner, allowing for both static and dynamic content.

final class MessageListController: UIViewController {
    
    // MARK: View's LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpMessagesListeners()
    }
    
    /// In Swift, the init method for a UIViewController subclass must ensure that all properties are initialized before calling super.init(nibName:bundle:).
    init(_ viewModel: ChatRoomViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    deinit {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    private let viewModel: ChatRoomViewModel
    private let cellIdentifier = "MessageListControllerCells"
    private var subscriptions = Set<AnyCancellable>()
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: Methods
    private func setUpViews() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    private func setUpMessagesListeners() {
        let delay = 200
        viewModel.$messages
            .debounce(for: .milliseconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }.store(in: &subscriptions)
    }
}

// MARK: UITableViewDelegate & UITableViewDataSource
extension MessageListController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        
        let message = viewModel.messages[indexPath.row]
        
        /// UIHostingConfiguration is a part of UIKit that allows you to integrate SwiftUI views within a UITableViewCell or UICollectionViewCell. This makes it easier to use SwiftUI's declarative syntax and modern UI features within a UIKit-based project..
        cell.contentConfiguration = UIHostingConfiguration {
            switch message.type {
            case .text:
                BubbleTextView(item: message)
            case .video,.photo:
                BubbleImageView(item: message)
            case .audio:
                BubbleAudioView(item: message)
            }
        }
        return cell
    }
    
    // Use a uikit for tableView, use a swiftui as the cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

/*
 Here are some key features and components of a UITableView:

 Cells: The primary building block of a table view is the UITableViewCell. Each cell represents a single row in the table and can be customized to display any content, such as text, images, or custom views.

 Sections: A UITableView can be divided into multiple sections, each containing multiple rows. Sections can have headers and footers to provide additional context or grouping for the rows they contain.

 Data Source: The UITableViewDataSource protocol is used to provide the data for the table view. This includes methods to specify the number of sections, the number of rows in each section, and the content for each cell.

 Delegate: The UITableViewDelegate protocol allows for handling interactions with the table view, such as selecting a row, editing actions, and managing the appearance of headers, footers, and cells.

 Reuse Identifier: To improve performance, UITableView uses a reuse identifier system. Cells that scroll off-screen are placed into a reuse queue and reused when new cells scroll on-screen. This minimizes the memory footprint and enhances scrolling performance.
 */


#Preview {
    MessageListView(ChatRoomViewModel(.placeholder))
}
