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
        messagesCollectionView.backgroundColor = .clear
        view.backgroundColor = .clear
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
    private var lastScrollPosition: String?
    
    // UIKIT
    private lazy var pullToRefresh: UIRefreshControl = {
        let pullToRefresh = UIRefreshControl()
        pullToRefresh.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return pullToRefresh
    }()
    
//    private lazy var tableView: UITableView = {
//        let tableView = UITableView()
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.separatorStyle = .none
//        tableView.backgroundColor = UIColor.gray.withAlphaComponent(0.4)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        
//        /// fix scroll
//        tableView.contentInset = .init(top: 0, left: 0, bottom: 60, right: 0)
//        tableView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: 60, right: 0)
//        
//        return tableView
//    }()
    
    private let compositionalLayout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
        var listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
        listConfig.backgroundColor = UIColor.gray.withAlphaComponent(0.2)
        listConfig.showsSeparators = false
        let section = NSCollectionLayoutSection.list(using: listConfig, layoutEnvironment: layoutEnvironment)
        section.contentInsets.leading = 0
        section.contentInsets.trailing = 0
        /// This is going to reduce inter item spacing
        section.interGroupSpacing = -10
        return section
    }
    
    private lazy var messagesCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.selfSizingInvalidation = .enabledIncludingConstraints
        collectionView.contentInset = .init(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.scrollIndicatorInsets = .init(top: 0, left: 0, bottom: 60, right: 0)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.backgroundColor = .clear
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.refreshControl = pullToRefresh // set the scroll on the header for refresh more messages
        return collectionView
    }()
    
    private let backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView(image: .chatbackground)
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageView
        
    }()
    
    // MARK: Methods
    private func setUpViews() {
        view.addSubview(backgroundImageView)
        view.addSubview(messagesCollectionView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }
    
    private func setUpMessagesListeners() {
        let delay = 200
        // messages
        viewModel.$messages
            .debounce(for: .milliseconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.messagesCollectionView.reloadData()
            }.store(in: &subscriptions)
        
        // scroll to bottom
        viewModel.$scrollToBottomRequest
            .debounce(for: .milliseconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] scrollRequest in
                if scrollRequest.scroll {
                    self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: scrollRequest.isAnimate)
                }
            }.store(in: &subscriptions)
        
        // is paginating, i wanna know when we are done paginating and then i want to scroll to the first item that we were at before we pull to refresh
        viewModel.$isPaginating
            .debounce(for: .milliseconds(delay), scheduler: DispatchQueue.main)
            .sink {[weak self] isPaginating in
                guard let self = self, let lastScrollPosition else { return }
                if isPaginating == false {
                    guard let index = viewModel.messages.firstIndex(where: {
                        $0.id == lastScrollPosition
                    }) else { return }
                    let indexPath = IndexPath(item: index, section: 0)
                    self.messagesCollectionView.scrollToItem(at: indexPath, at: .top, animated: false)
                    self.pullToRefresh.endRefreshing()
                }
            }.store(in: &subscriptions)
    }
    
    // Get more Messages
    @objc private func refreshData() {
        // The lastScrollPosition use for flag the last position of the array messages (when use fetch more data, the view will auto scroll to the bottom of the char room screen) and its will to fix that
        lastScrollPosition = viewModel.messages.first?.id
        viewModel.getMessages()
    }
}

// MARK: UITableViewDelegate & UITableViewDataSource
extension MessageListController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.messages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        cell.backgroundColor = .clear
        
        let message = viewModel.messages[indexPath.item]
        let isNewDay = viewModel.isNewDay(for: message, at: indexPath.item)
        let showSenderName = viewModel.showSenderName(for: message, at: indexPath.item)
        
        /// UIHostingConfiguration is a part of UIKit that allows you to integrate SwiftUI views within a UITableViewCell or UICollectionViewCell. This makes it easier to use SwiftUI's declarative syntax and modern UI features within a UIKit-based project..
        cell.contentConfiguration = UIHostingConfiguration {
            BubbleView(message: message, channel: viewModel.channel, isNewDay: isNewDay, showSenderName: showSenderName)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIApplication.dismissKeyboard() // dismiss the keyboard before play av video
        let messageItem = viewModel.messages[indexPath.row]
        
        // Show media player
        switch messageItem.type {
        case .video:
            guard let videoURLString = messageItem.videoURL,
                  let videoURL = URL(string: videoURLString)
            else { return }
            viewModel.showMediaPlayer(videoURL)
            
            
        default:
            break
        }
    }
    
    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
//        cell.backgroundColor = .clear
//        cell.selectionStyle = .none
//        
//        let message = viewModel.messages[indexPath.row]
//        
//        /// UIHostingConfiguration is a part of UIKit that allows you to integrate SwiftUI views within a UITableViewCell or UICollectionViewCell. This makes it easier to use SwiftUI's declarative syntax and modern UI features within a UIKit-based project..
//        cell.contentConfiguration = UIHostingConfiguration {
//            switch message.type {
//            case .text:
//                BubbleTextView(item: message)
//            case .video,.photo:
//                BubbleImageView(item: message)
//            case .audio:
//                BubbleAudioView(item: message)
//            case .admin(let adminType):
//                switch adminType {
//                case .channelCreation:
//                    ChannelCreationTextView()
//                    
//                    if viewModel.channel.isGroupChat {
//                        AdminMessageTextView(channel: viewModel.channel)
//                    }
//                default:
//                    Text("Unknown")
//                }
//            } 
//        }
//        return cell
//    }
    
    // Use a uikit for tableView, use a swiftui as the cell
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return viewModel.messages.count
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    // Click to message for play video type
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        
//        UIApplication.dismissKeyboard() // dismiss the keyboard before play av video
//        let messageItem = viewModel.messages[indexPath.row]
//        
//        // Show media player
//        switch messageItem.type {
//        case .video:
//            guard let videoURLString = messageItem.videoURL,
//                  let videoURL = URL(string: videoURLString)
//            else { return }
//            viewModel.showMediaPlayer(videoURL)
//            
//        case .audio:
//            guard let audioUrlString = messageItem.audioURL,
//                  let audioURL = URL(string: audioUrlString)
//            else { return }
//            viewModel.showMediaPlayer(audioURL)
//            
//        default:
//            break
//        }
//    }
}

private extension UICollectionView {
    
    func scrollToLastItem(at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        
        guard numberOfItems(inSection: numberOfSections - 1) > 0 else { return }
        
        let lastSectionIndex = numberOfSections - 1
        let lastRowIndex = numberOfItems(inSection: lastSectionIndex) - 1
        let lastRowIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
        scrollToItem(at: lastRowIndexPath, at: scrollPosition, animated: animated)
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
        .ignoresSafeArea()
}
