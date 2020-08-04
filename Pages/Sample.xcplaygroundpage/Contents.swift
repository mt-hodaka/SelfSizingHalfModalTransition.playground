import UIKit
import WebKit
import XCPlayground
import PlaygroundSupport

public protocol Mutatable: Any {}

extension Mutatable {
    /// Copy value type, set the properties to it using closure, and return it.
    ///
    /// usage:
    /// ```swift
    /// // without Mutatable
    /// var cal = Calendar(identifier: .gregorian)
    /// cal.locale = Locale(identifier: "en_US_POSIX")
    ///
    /// // with Mutatable
    /// let cal = Calendar(identifier: .gregorian).mutated {
    ///     $0.locale = Locale.init(identifier: "en_US_POSIX")
    /// }
    /// ```
    public func mutated(mutator: (inout Self) -> Void) -> Self {
        var newValue = self
        mutator(&newValue)
        return newValue
    }
}

extension IndexPath: Mutatable {}
extension Calendar: Mutatable {}
extension DateComponents: Mutatable {}
extension DateInterval: Mutatable {}
extension Date: Mutatable {}
extension URL: Mutatable {}
extension URLRequest: Mutatable {}
extension URLComponents: Mutatable {}
extension CGRect: Mutatable {}
extension CGPoint: Mutatable {}
extension CGSize: Mutatable {}
extension CGVector: Mutatable {}
extension UIEdgeInsets: Mutatable {}
extension UIOffset: Mutatable {}
extension UIRectEdge: Mutatable {}
extension Array: Mutatable {}
extension Dictionary: Mutatable {}
extension Set: Mutatable {}

public protocol Applyable: AnyObject {}

extension Applyable {
    /// Set Properties to object using closure.
    ///
    /// usage:
    /// ```swift
    /// let myView = UIView().apply {
    ///     $0.backgroundColor = .white
    /// }
    /// ```
    @discardableResult
    public func apply(applyer: (Self) -> Void) -> Self {
        applyer(self)
        return self
    }
}

extension NSObject: Applyable {}
extension JSONDecoder: Applyable {}
extension JSONEncoder: Applyable {}

// MARK: - Impl

class HalfModalTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        HalfModalPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

class HalfModalPresentationController: UIPresentationController {
    lazy var overlayView = UIView().apply {
        $0.backgroundColor = .black
        $0.alpha = 0.0
    }

    func presentationAlongsideTransition(_ context: UIViewControllerTransitionCoordinatorContext) {
        overlayView.alpha = 0.5
    }

    func dismissalAlongsideTransition(_ context: UIViewControllerTransitionCoordinatorContext) {
        overlayView.alpha = 0.0
    }

    @objc
    func didTapOverlayView(_ sender: UITapGestureRecognizer) {
        presentedViewController.dismiss(animated: true, completion: nil)
    }

    // MARK: overrides

    override func containerViewWillLayoutSubviews() {
        overlayView.frame = containerView!.frame

        guard
            let presentedView = presentedView,
            let presentedViewSuperView = presentedView.superview
            else { return }

        presentedView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            presentedView.leadingAnchor.constraint(equalTo: presentedViewSuperView.leadingAnchor),
            presentedView.trailingAnchor.constraint(equalTo: presentedViewSuperView.trailingAnchor),
            presentedView.bottomAnchor.constraint(equalTo: presentedViewSuperView.bottomAnchor),
        ])

        if let scrollView = (presentedView as? UIScrollView) {
            NSLayoutConstraint.activate([
                scrollView.heightAnchor.constraint(equalToConstant: scrollView.contentSize.height),
            ])
        }
    }

    override func containerViewDidLayoutSubviews() {
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        overlayView.apply {
            $0.frame = containerView.bounds
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOverlayView(_:))))
        }

        containerView.insertSubview(overlayView, at: 0)

        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: presentationAlongsideTransition,
            completion: nil
        )
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: dismissalAlongsideTransition,
            completion: nil
        )
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            overlayView.removeFromSuperview()
        }
    }
}

// MARK: - ViewControllers

class FirstControllerViewController: UIViewController {
    private lazy var customTransitioningDelegate = HalfModalTransitioningDelegate()

    @IBAction func openSecondButton(_ sender: UIButton) {
        let modalViewController = SecondViewController().apply {
            $0.modalPresentationStyle = .custom
            $0.transitioningDelegate = customTransitioningDelegate
        }
        present(modalViewController, animated: true, completion: nil)
    }

    @IBAction func openTableButton(_ sender: UIButton) {
        let modalViewController = TableViewController().apply {
            $0.modalPresentationStyle = .custom
            $0.transitioningDelegate = customTransitioningDelegate
        }
        present(modalViewController, animated: true, completion: nil)
    }

    override func loadView() {
        view = UIView().apply {
            $0.backgroundColor = .white
        }

        let button1 = UIButton(type: .system).apply {
            $0.setTitle("open SecondViewController", for: .normal)
            $0.addTarget(self, action: #selector(openSecondButton(_:)), for: .touchUpInside)
        }

        let button2 = UIButton(type: .system).apply {
            $0.setTitle("open TableViewController", for: .normal)
            $0.addTarget(self, action: #selector(openTableButton(_:)), for: .touchUpInside)
        }

        let stack = UIStackView(arrangedSubviews: [button1, button2]).apply {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .vertical
        }

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: stack.superview!.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: stack.superview!.centerYAnchor),
        ])
    }
}

class SecondViewController: UIViewController {
    override func loadView() {
        view = UIView().apply {
            $0.backgroundColor = .white
            $0.layer.cornerRadius = 8.0
            $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            $0.clipsToBounds = true

            $0.heightAnchor.constraint(equalToConstant: 240).isActive = true
        }
    }
}

class TableViewController: UITableViewController {
    private let reuseIdentifier = "Cell"

    private let models = [
        "AAA",
        "BBB",
        "CCC",
        "DDD",
        "EEE",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        (1...models.count).randomElement()!
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath).apply {
            $0.textLabel?.text = models[indexPath.row]
        }
    }
}

// MARK: - Play

let vc = FirstControllerViewController().apply {
    $0.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
}

let nc = UINavigationController(rootViewController: vc).apply {
    $0.setToolbarHidden(true, animated: false)
}

PlaygroundPage.current.liveView = nc
PlaygroundPage.current.needsIndefiniteExecution = true

