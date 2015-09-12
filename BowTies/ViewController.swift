//
//  ViewController.swift
//  BowTies
//
//  Created by 刘业清 on 15/7/26.
//  Copyright (c) 2015年 Guadoo Group. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var timesWornLabel: UILabel!
    @IBOutlet weak var lastWornLabel: UILabel!
    @IBOutlet weak var favoriteLabel: UILabel!
    
    var managedContext: NSManagedObjectContext!
    var currentBowtie: Bowtie!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //1 读取SampleData plist信息 并存入Core Data
        insertSampleData()
        
        //2 根据Segment的title fetch Bowtie 中的数据
        let request = NSFetchRequest(entityName: "Bowtie")
        let firstTitle = segmentedControl.titleForSegmentAtIndex(0)
        request.predicate = NSPredicate(format: "searchKey ==%@", firstTitle!)
        
        //3 获取 fetch 结果
        var error: NSError? = nil
        var results = managedContext.executeFetchRequest(request, error: &error) as? [Bowtie]
        
        //4 如果获得结果 currentBowtie为bowties数组的第一个
        if let bowties = results{
            currentBowtie = bowties[0]
            populate(currentBowtie)
        }else{
            println("Couldn't fetch \(error), \(error!.userInfo)")
        }
    }
    
    // 更新 view 中的显示对象
    func populate(bowtie: Bowtie){
        
        imageView.image = UIImage(data: bowtie.photoData)
        nameLabel.text = bowtie.name
        ratingLabel.text = "Rating: \(bowtie.rating.doubleValue)/5"
        
        timesWornLabel.text = "# times worn: \(bowtie.timesWorn.integerValue)"
        
        // 设置显示时间格式
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        dateFormatter.timeStyle = .NoStyle
        lastWornLabel.text = "last worn: " + dateFormatter.stringFromDate(bowtie.lastWorn)
        
        // 根据isFavorite 判断是否显示 favoriteLabel
        favoriteLabel.hidden = !bowtie.isFavorite.boolValue
        
        // 设置整个 View 的色调
        view.tintColor = bowtie.tintColor as! UIColor
    }
    

    @IBAction func segmentedControl(control: UISegmentedControl) {
        
        // 获取 segement 的 title
        let selectedValue = control.titleForSegmentAtIndex(control.selectedSegmentIndex)
        
        // searchKey = segement title 为条件 fetch Bowtie
        let fetchRequest = NSFetchRequest(entityName: "Bowtie")
        
        fetchRequest.predicate = NSPredicate(format: "searchKey == %@", selectedValue!)
        
        var error: NSError?
        
        let results = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [Bowtie]?
        
        // fetch 结果作为当前 Bowtie
        if let bowties = results{
            currentBowtie = bowties.last!
            populate(currentBowtie)
        }else{
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }

    @IBAction func wear(sender: AnyObject) {
        
        let times = currentBowtie.timesWorn.integerValue
        currentBowtie.timesWorn = NSNumber(integer: (times+1)) // INT 到 NSNumber 的转换方法
        
        currentBowtie.lastWorn = NSDate()
        
        var error: NSError?
        if !managedContext.save(&error){
            println("Couldn't save \(error), \(error!.userInfo)")
        }
        
        populate(currentBowtie)
        
    }
    
    // 点击 Rate 后，显示 alert 提示框
    @IBAction func rate(sender: AnyObject) {
        
        let alert = UIAlertController(title: "New Rating", message: "Rate this bow tie", preferredStyle: UIAlertControllerStyle.Alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
            
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action: UIAlertAction!) -> Void in
        
            let textField = alert.textFields![0] as! UITextField
            self.updateRating(textField.text) // 调用 updateRating 方法更新
        }
        
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in
            
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        self.presentViewController(alert, animated: true, completion:nil)
    }
    
    
    func updateRating(numericString: String){
        
        currentBowtie.rating = (numericString as NSString).doubleValue
        
        var error: NSError?
        
        // Core Data中添加了数据校验 根据校验结果 处理错误
        if !managedContext.save(&error){
            if error!.code == NSValidationNumberTooLargeError || error!.code == NSValidationNumberTooSmallError{
                rate(currentBowtie)
            }
        }else{
            populate(currentBowtie)
        }
    }
    
    
    //Insert sample data
    func insertSampleData(){
        
        // 检查依据searchiKey fetch Bowtie 是否有值
        let fetchRequest = NSFetchRequest(entityName: "Bowtie")
        fetchRequest.predicate = NSPredicate(format: "searchKey != nil")
        
        // count fetch 结果 count大于0 有值 则 返回
        let count = managedContext.countForFetchRequest(fetchRequest, error: nil)
        
        if count > 0 {return}
        
        // 获取 SampleData.plist 路径
        let path = NSBundle.mainBundle().pathForResource("SampleData", ofType: "plist")
        
        // 通过路径 加载 SampleData 到 NSArray
        let dataArray = NSArray(contentsOfFile: path!)!
        
        // 依次读取 dataArray 中的数据 并赋值给 bowtie 对象
        for dict : AnyObject in dataArray{
            
            let entity = NSEntityDescription.entityForName("Bowtie", inManagedObjectContext: managedContext)
            let bowtie = Bowtie(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            let btDict = dict as! NSDictionary
            
            bowtie.name = btDict["name"] as! String
            bowtie.searchKey = btDict["searchKey"] as! String
            bowtie.rating = btDict["rating"] as! NSNumber
            
            // 颜色处理调研方法 colorFromDict
            let tintColorDict = btDict["tintColor"] as! NSDictionary
            bowtie.tintColor = colorFromDict(tintColorDict)
            
            // image 处理: 读取 dataArray中的imageName, 根据 imageName 实例 image 对象, image 转换 NSData
            let imageName = btDict["imageName"] as! String
            let image = UIImage(named: imageName)
            let photoData = UIImagePNGRepresentation(image)
            bowtie.photoData = photoData
            
            bowtie.lastWorn = btDict["lastWorn"] as! NSDate
            
            bowtie.timesWorn = btDict["timesWorn"] as! NSNumber
            
            bowtie.isFavorite = btDict["isFavorite"] as! NSNumber

        }
        
        var error: NSError?
        if !managedContext.save(&error){
            println("Could not save \(error), \(error!.userInfo)")
        }
    }
    
    func colorFromDict(dict: NSDictionary) -> UIColor{
        
        let red = dict["red"] as! NSNumber
        let green = dict["green"] as! NSNumber
        let blue = dict["blue"] as! NSNumber
        
        let color = UIColor(red: CGFloat(red)/255.0, green: CGFloat(green)/255.0, blue: CGFloat(blue)/255.0, alpha: 1)
        
        return color
    }
    
}

