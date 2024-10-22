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
        setUpLongPressGestureRecorgnizer()
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
    
    // MARK: Custom Reactions Properties
    private var startingFrame: CGRect?
    private var blurView: UIVisualEffectView?
    private var focusedView: UIView?
    private var highlightedCell: UICollectionViewCell?
    private var reactionHostVC: UIViewController?
    private var messageMenuHostVC: UIViewController?
    
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
    
    // Button Pull Down
    private let pullToDownHUBView: UIButton = {
        var buttonConfig = UIButton.Configuration.filled()
        var imageConfig = UIImage.SymbolConfiguration(pointSize: 10, weight: .black)
        
        let image = UIImage(systemName: "arrow.up.circle.fill", withConfiguration: imageConfig)
        buttonConfig.image = image
        buttonConfig.baseBackgroundColor = .bubbleGreen
        buttonConfig.baseForegroundColor = .whatsAppBlack
        buttonConfig.imagePadding = 5
        buttonConfig.cornerStyle = .capsule
        
        let font = UIFont.systemFont(ofSize: 12, weight: .black)
        buttonConfig.attributedTitle = AttributedString("Pull Down", attributes: AttributeContainer([NSAttributedString.Key.font: font]))
        let button = UIButton(configuration: buttonConfig)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.alpha = 0 // set opacity zero for default
        return button
    }()
    
    // MARK: Methods
    private func setUpViews() {
        view.addSubview(backgroundImageView)
        view.addSubview(messagesCollectionView)
        view.addSubview(pullToDownHUBView)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            messagesCollectionView.topAnchor.constraint(equalTo: view.topAnchor),
            messagesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            messagesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            messagesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            pullToDownHUBView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            pullToDownHUBView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
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
        viewModel.paginationMoreMessages()
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
    
    // Handle scroll action (dislay button when user scroll over the contents)
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= 0 {
            pullToDownHUBView.alpha = viewModel.isPaginatable ? 1 : 0
            print("CollectionView is at the top: \(scrollView.contentOffset.y)")
        } else {
            pullToDownHUBView.alpha = 0
            print("CollectionView is not at the top: \(scrollView.contentOffset.y)")
        }
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

// MARK: Context Menu Interactions
extension MessageListController {
    
    private func setUpLongPressGestureRecorgnizer() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(showContextMenu))
        
        longPressGesture.minimumPressDuration = 0.5
        messagesCollectionView.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func showContextMenu(_ gesture: UILongPressGestureRecognizer) {
        
        /// Avoid duplicate call this function twice times
        guard gesture.state == .began else { return }
        
        /// Get the point current did selected
        let point = gesture.location(in: messagesCollectionView)
        guard let indexPath = messagesCollectionView.indexPathForItem(at: point) else { return  }
        
        /// Get message
        let message = viewModel.messages[indexPath.item]
        
        /// If message is the admin type -> not excute the long press gesture
        guard message.type.isAdminMessaage == false else { return }
        
        /// Select cell
        guard let selectedCell = messagesCollectionView.cellForItem(at: indexPath) else { return }
        
        /// save the original frame of selectedCell has just clicked (postion xy , frame xy)
        startingFrame = selectedCell.superview?.convert(selectedCell.frame, to: nil)
        
        /// capture selectedView current into snapshotView
        guard let snapshotCell = selectedCell.snapshotView(afterScreenUpdates: false) else { return }
        
        /// main frame for display the reaction will bubble the main chat room view
        focusedView = UIView(frame: startingFrame ?? .zero)
        guard let focusedView else { return }
        focusedView.isUserInteractionEnabled = false
        
        /// set action dismiss function by onTapGesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissContextMenu))
        
        /// blur view
        let blurEffect = UIBlurEffect(style: .regular)
        blurView = UIVisualEffectView(effect: blurEffect)
        guard let blurView else { return }
        blurView.contentView.isUserInteractionEnabled = true
        blurView.contentView.addGestureRecognizer(tapGesture) // at gesture for blur
        blurView.alpha = 0
        
        /// assign highlightedCell for fix the junky bug when dismiss the reaction
        highlightedCell = selectedCell
        highlightedCell?.alpha = 0
        
        
        /// get key window is entire window screen
        guard let keyWindow = UIWindowScene.current?.keyWindow else { return }
        
        /// at view into keyWindow
        keyWindow.addSubview(blurView)
        keyWindow.addSubview(focusedView)
        focusedView.addSubview(snapshotCell)
        
        /// cover blur entire the screen
        blurView.frame = keyWindow.frame
        
        /// attach the menu view to bottom of the message view
        let isNewDay = viewModel.isNewDay(for: message, at: indexPath.item)
        attachMenuAction(to: message, in: keyWindow, isNewDay)
        
        /// Check the message height wheather large more than main screen or not -> true -> shrink that message for display the emotion interaction
        let shrinkCell = shrinkCell(startingFrame?.height ?? 0)
        
        
        /// animation for display
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn) {
            
            blurView.alpha = 1
            
            /// set frame for object into keyWindow
            focusedView.center.y = keyWindow.center.y - 60 // set the focused view center y-axis
            snapshotCell.frame = focusedView.bounds
            
            /// Set shadow
            snapshotCell.layer.applyShadow(color: .gray, alpha: 0.2, x: 0, y: 2, blur: 4) // Extension in the bottom
            
            /// If shrink cell
            if shrinkCell {
                let xTranslation: CGFloat = message.direction == .received ? -80 : 80
                let translation = CGAffineTransform(translationX: xTranslation, y: 0.5)
                focusedView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).concatenating(translation)
            }
        }
    }
    
    private func attachMenuAction(to message: MessageItem, in window: UIWindow, _ isNewDay: Bool) {
        /// Convert a swiftUI view to UIKit view
        guard let focusedView, let startingFrame else { return }
        
        /// Check shrink cell
        let shrinkCell = shrinkCell(startingFrame.height)
        
        // MARK: REACTION PICKER VIEW
        let reactionPickerView = ReactionPickerView(message: message)
        
        let reactionHostVC = UIHostingController(rootView: reactionPickerView)
        reactionHostVC.view.backgroundColor = .clear
        reactionHostVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        /// hidden the timestamp date below the reaction component if isNewDay
        var reactionPadding: CGFloat = isNewDay ? 45 : 5
        
        /// decrease the padding after the message has just shrinked
        if shrinkCell {
            reactionPadding += (startingFrame.height / 3)
        }
        
        window.addSubview(reactionHostVC.view)
        /// bottom Anchor
        reactionHostVC.view.bottomAnchor.constraint(equalTo: focusedView.topAnchor, constant: reactionPadding).isActive = true
        /// leading Anchor
        reactionHostVC.view.leadingAnchor.constraint(equalTo: focusedView.leadingAnchor, constant: 20).isActive = message.direction == .received
        /// trailing Anchor
        reactionHostVC.view.trailingAnchor.constraint(equalTo: focusedView.trailingAnchor, constant: -20).isActive = message.direction == .sent
        
        // MARK: MESSAGE MENU VIEW
        let messageMenuView = MessageMenuView(message: message)
        
        let messageMenuHostVC = UIHostingController(rootView: messageMenuView)
        messageMenuHostVC.view.backgroundColor = .clear
        messageMenuHostVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        /// same thing reaction view controller above
        var menuPadding: CGFloat = 0
        if shrinkCell {
            menuPadding -= (startingFrame.height / 2.5)
        }
        
        window.addSubview(messageMenuHostVC.view)
        /// top Anchor
        messageMenuHostVC.view.topAnchor.constraint(equalTo: focusedView.bottomAnchor, constant: menuPadding).isActive = true
        /// leading Anchor
        messageMenuHostVC.view.leadingAnchor.constraint(equalTo: focusedView.leadingAnchor, constant: 20).isActive = message.direction == .received
        /// trailing Anchor
        messageMenuHostVC.view.trailingAnchor.constraint(equalTo: focusedView.trailingAnchor, constant: -20).isActive = message.direction == .sent
        
        
        self.reactionHostVC = reactionHostVC
        self.messageMenuHostVC = messageMenuHostVC
    }
    
    @objc func dismissContextMenu() {
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 1,
            options: .curveEaseOut
        ) { [weak self] in
            guard let self = self else { return }
            
            focusedView?.transform = .identity
            
            /// set focusedView become to startingFrame at position begin
            focusedView?.frame = startingFrame ?? .zero
            reactionHostVC?.view.removeFromSuperview()
            messageMenuHostVC?.view.removeFromSuperview()
            blurView?.alpha = 0
        } completion: { [weak self] _ in
            /// disappear the focused view and display the main cell view to fix the junky display
            self?.highlightedCell?.alpha = 1
            /// remove out the window screen
            self?.blurView?.removeFromSuperview()
            self?.focusedView?.removeFromSuperview()
            
            // Clear Preference
            self?.highlightedCell = nil
            self?.blurView = nil
            self?.focusedView = nil
            self?.messageMenuHostVC = nil
            self?.reactionHostVC = nil
        }
    }
    
    /// Check if height message more than will be shrink
    private func shrinkCell(_ cellHeight: CGFloat) -> Bool {
        let screenHeight = (UIWindowScene.current?.screenHeight ?? 0) / 1.2
        let spacingForMenuView = screenHeight - cellHeight
        return spacingForMenuView < 190
    }
}

/// Extension of scroll to bottom action
private extension UICollectionView {
    
    func scrollToLastItem(at scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        
        guard numberOfItems(inSection: numberOfSections - 1) > 0 else { return }
        
        let lastSectionIndex = numberOfSections - 1
        let lastRowIndex = numberOfItems(inSection: lastSectionIndex) - 1
        let lastRowIndexPath = IndexPath(row: lastRowIndex, section: lastSectionIndex)
        scrollToItem(at: lastRowIndexPath, at: scrollPosition, animated: animated)
    }
}

/// Extension of shadow
extension CALayer {
    func applyShadow(color: UIColor, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = .init(width: x, height: y)
        shadowRadius = blur
        masksToBounds = false //  The sublayers and content can extend beyond the layer’s bounds. This is useful when you want to apply shadows,
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
        .environmentObject(VoiceMessagePlayer())
}
