//
//  OnboardingViewController.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-09-18.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {

    @IBOutlet var closeButton: FancyButton!
    var hasOpenedIntroduction = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.alpha = 0.0
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }
    
    @objc func applicationDidBecomeActive() {
        if hasOpenedIntroduction {
            closeButton.setTitle("Done", for: .normal)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if animated {
            UIView.animate(withDuration: 0.7, delay: 0.6, options: [.allowUserInteraction, .curveEaseInOut], animations: {
                self.view.alpha = 1.0
            }, completion: nil)
        } else {
            self.view.alpha = 1.0
        }
    }

    @IBAction func openIntroduction(_ sender: Any) {
        let url = URL(string: "https://ncase.me/remember/")!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
        hasOpenedIntroduction = true
    }
    
    @IBAction func close(_ sender: Any) {
        UIView.animate(withDuration: 0.4, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: false, completion: nil)
        })
    }
}
