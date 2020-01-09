//
//  OnboardingViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-09-18.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var fadeView: GradientView!
    @IBOutlet var callToActionButton: FancyButton!
    
    @IBOutlet var topSpacerConstraint: NSLayoutConstraint!
    @IBOutlet var sectionSpacerConstraints: [NSLayoutConstraint]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
        } else {
            tableView.contentInset.top = 20.0
            tableView.scrollIndicatorInsets.top = 20.0
            tableView.contentOffset.y = -20.0
        }
        
        // iPhone 11 Pro
        if tableView.frame.height > 800 && tableView.frame.height < 840 {
            for constraint in sectionSpacerConstraints {
                constraint.constant = 32.0
            }
        }
        
        // if the entire onboarding can be shown then scroll away the skip button
        if tableView.frame.height > callToActionButton.frame.maxY - 46.0 {
            tableView.contentOffset.y = 46.0
        }
        
        let newHeight = callToActionButton.frame.origin.y + callToActionButton.frame.size.height + 22.0 + 100
        tableView.tableFooterView?.frame.size.height = newHeight
        tableView.tableFooterView = tableView.tableFooterView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if ImageManager.containsAnyCards() || ImageManager.containsDrafts() {
            view.isHidden = true
            close(self)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let newHeight = callToActionButton.frame.origin.y + callToActionButton.frame.size.height + 22.0
        if newHeight > tableView.tableFooterView?.frame.size.height ?? 0 {
            tableView.tableFooterView?.frame.size.height = newHeight
            tableView.tableFooterView = tableView.tableFooterView
        }
    }
    
    @IBAction func openIntroduction(_ sender: Any) {
        let url = URL(string: "https://ncase.me/remember/")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
        // call view will appear since over full screen for the modal supresses it
        if let startViewController = (presentingViewController as? UINavigationController)?.viewControllers.first as? StartViewController {
            startViewController.viewWillAppear(false)
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let distanceToButton = callToActionButton.frame.minY - (scrollView.contentOffset.y + scrollView.frame.height)
        if distanceToButton < 0 {
            fadeView.alpha = 0.0
        } else {
            fadeView.alpha = 1.0
        }
    }
}
