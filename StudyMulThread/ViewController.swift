//
//  ViewController.swift
//  StudyMulThread
//
//  Created by 吴红星 on 2021/12/21.
//

import UIKit

var array: [Int] = []
let lock = NSLock()
func addModule(value: Int) {
    array.append(value)
}

func getModules() -> [Int] {
    return array
}

class ViewController: UIViewController {
    private let array = ["主同步", "主异步", "全局同步", "全局异步",
                         "串行同步", "串行异步", "并行同步", "并行异步",
                         "栅栏函数", "混合研究", "after", "group-enter-leave",
                         "gruop-wait", "卖票-线程不安全", "卖票-线程安全", "异步转同步-group",
                         "异步转同步-锁", "异步转同步-同步任务", "异步转同步-串行队列",
                         "异步转同步-信号量"]

    override func viewDidLoad() {
        array.enumerated().forEach { (index, s) in
            let button = UIButton(frame: CGRect(x: index % 2 * 160, y: index / 2 * 50 + 100, width: 140, height: 40))
            button.setTitle(s, for: .normal)
            button.backgroundColor = .red
            button.tag = index
            button.addTarget(self, action: #selector(handle(_:)), for: .touchUpInside)
            view.addSubview(button)
        }
        
        
    }
    
    @objc
    private func handle(_ button: UIButton) {
        switch button.tag {
        case 0:
            print(1)
            DispatchQueue.main.sync {
                print(2)
            }
            print(3)
        case 1:
            print(1, Thread.current)
            DispatchQueue.main.async {
                print(2, Thread.current)
            }
            print(3, Thread.current)
        case 2:
            print(1, Thread.current)
            DispatchQueue.global().sync {
                print(2, Thread.current)
            }
            print(3, Thread.current)
        case 3:
            print(1, Thread.current)
            for _ in 0 ..< 10 {
                DispatchQueue.global().async {
                    print(2, Thread.current)
                }
            }
            print(3, Thread.current)
        case 4:
            print(1, Thread.current)
            DispatchQueue(label: "serial").sync {
                print(2, Thread.current)
            }
            print(3, Thread.current)
        case 5:
            print(1, Thread.current)
            DispatchQueue(label: "serial").async {
                print(2, Thread.current)
            }
            print(3, Thread.current)
        case 6:
            print(1, Thread.current)
            DispatchQueue(label: "concurrent", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil).sync {
                print(2, Thread.current)
            }
            print(3, Thread.current)
        case 7:
            print(1, Thread.current)
            for _ in 0 ..< 10 {
                DispatchQueue(label: "concurrent", qos: DispatchQoS.default, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit, target: nil).async {
                    print(2, Thread.current)
                }
            }
            print(3, Thread.current)
        case 8:
            let queue = DispatchQueue(label: "concurrent", attributes: .concurrent)
            for i in 0 ..< 10 {
                queue.async {
                    print(i)
                }
            }
            // 如果这里是 sync 那么，这行执行完成之后才会执行 after 1
            queue.async(execute: DispatchWorkItem(flags: .barrier, block: {
                print("===栅栏函数===")
            }))
            for i in 11 ..< 20 {
                queue.async {
                    print(i)
                }
            }
            print("after 1")
        case 9:
            print("begin")
            DispatchQueue.global().async {
                let queue = DispatchQueue(label: "xxx", attributes: .concurrent)
                (0 ..< 10).forEach { i in
                    queue.async {
                        print(i)
                    }
                }
//                queue.sync {
//                    Thread.sleep(forTimeInterval: 1)
//                    print("我是分隔线")
//                }
                queue.async(execute: DispatchWorkItem(flags: .barrier, block: {
                    Thread.sleep(forTimeInterval: 1)
                    print("我是分隔线")
                }))
                (10 ..< 20).forEach { i in
                    queue.async {
                        print(i)
                    }
                }
                queue.sync {
                    (20 ..< 30).forEach { i in
                        print(i)
                    }
                }
                
            }
            print("end")
        case 10:
            print(1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                print("2s 后执行")
            }
            print(2)
            sleep(3)
            print(3)
        case 11:
            let group = DispatchGroup()
            let queue = DispatchQueue(label: "xxx", attributes: .concurrent)
            var result1 = 0
            group.enter()
            queue.async {
                sleep(1)
                result1 = 10
                group.leave()
            }
            var result2 = 0
            group.enter()
            queue.async {
                sleep(1)
                result2 = 20
                group.leave()
            }
            group.notify(queue: queue) {
                print("result: ", result1, result2)
            }
        case 12:
            print("groupWait-begin")
            print(self.groupWait())
            print("groupWait-end")
        case 13:
            let queue1 = DispatchQueue(label: "售票窗口1")
            let queue2 = DispatchQueue(label: "售票窗口2")
            queue1.async {
                self.saleTicketUnsafe()
            }
            queue2.async {
                self.saleTicketUnsafe()
            }
        case 14:
            let queue1 = DispatchQueue(label: "售票窗口1")
            let queue2 = DispatchQueue(label: "售票窗口2")
            queue1.async {
                self.saleTicket()
            }
            queue2.async {
                self.saleTicket()
            }
        case 15:
            print("同步开始")
            print(self.groupWait())
            print("同步结束")
        case 16:
            print("同步开始")
            print(self.asyncTosync2())
            print("同步结束")
        case 17:
            print("同步开始")
            print(self.asyncTosync3())
            print("同步结束")
        case 18:
            print("同步开始")
            print(self.asyncTosync4())
            print("同步结束")
        case 19:
            print("同步开始")
            print(self.asyncTosync5())
            print("同步结束")
        default:
            break
        }
    }
    
    var ticketCount = 10
    func saleTicketUnsafe() {
        while (true) {
            if ticketCount > 0 {
                ticketCount -= 1
                print("剩余票量: ", ticketCount)
                Thread.sleep(forTimeInterval: 0.1)
            } else {
                print("票卖完了")
                break
            }
        }
    }
    
    let semaphore = DispatchSemaphore(value: 1)
    func saleTicket() {
        while (true) {
            semaphore.wait()
            if ticketCount > 0 {
                ticketCount -= 1
                print("剩余票量: ", ticketCount)
                Thread.sleep(forTimeInterval: 0.1)
            } else {
                semaphore.signal()
                print("票卖完了")
                break
            }
            semaphore.signal()
        }
    }
    
    // 同步方式1
    func groupWait() -> Int {
        let group = DispatchGroup()
        let queue = DispatchQueue(label: "xxx", attributes: .concurrent)
        var res1 = 0
        var res2 = 0
        group.enter()
        queue.async {
            sleep(1)
            res1 = 10
            group.leave()
        }
        group.enter()
        queue.async {
            sleep(1)
            (0 ..< 10).forEach { i in
                res2 += res1
            }
            group.leave()
        }
        _ = group.wait(timeout: .distantFuture)
        return res1 + res2
    }
    
    // 同步方式2 -- 这个用锁有明显问题
    func asyncTosync2() -> Int {
        let queue = DispatchQueue(label: "xxx", attributes: .concurrent)
        let lock = NSLock()
        var res1 = 0
        var res2 = 0
        lock.lock()
        queue.async {
            sleep(1)
            res1 = 10
            lock.unlock()
        }
        lock.lock()
        queue.async {
            sleep(1)
            (0 ..< 10).forEach { i in
                res2 += res1
            }
            lock.unlock()
        }
        lock.lock()
        return res1 + res2
    }
    
    // 同步方式3
    func asyncTosync3() -> Int {
        let queue = DispatchQueue(label: "xxx")
        var res1 = 0
        var res2 = 0
        queue.async {
            sleep(1)
            res1 = 10
        }
        queue.async {
            sleep(1)
            (0 ..< 10).forEach { i in
                res2 += res1
            }
        }
        queue.sync {
            
        }
        return res1 + res2
    }
    
    // 同步方式4
    func asyncTosync4() -> Int {
        let queue = DispatchQueue(label: "xxx")
        var res1 = 0
        var res2 = 0
        queue.sync {
            sleep(1)
            res1 = 10
        }
        queue.sync {
            sleep(1)
            (0 ..< 10).forEach { i in
                res2 += res1
            }
        }
        return res1 + res2
    }
    
    // 同步方式5
    func asyncTosync5() -> Int {
        let queue = DispatchQueue(label: "xxx", attributes: .concurrent)
        let semaphore = DispatchSemaphore(value: 0)
        var res1 = 0
        var res2 = 0
        queue.async {
            sleep(1)
            res1 = 10
            semaphore.signal()
        }
        semaphore.wait()
        queue.async {
            sleep(1)
            (0 ..< 10).forEach { i in
                res2 += res1
            }
            semaphore.signal()
        }
        semaphore.wait()
        return res1 + res2
    }
}

