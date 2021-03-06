//
//  MobileTicketQueryService.swift
//  Train12306
//
//  Created by fancymax on 15/10/24.
//  Copyright © 2015年 fancy. All rights reserved.
//

import Foundation

extension Service {
    
    func getTicket(leftTicketDTO:LeftTicketDTO,successHandler:()->(),failHandler:()->())
    {
        let initOperation = getLeftTicketInit()
        let logOperation = getLeftTicketLog(leftTicketDTO, successHandler: {}, failHandler: failHandler)
        let queryOperation = getLeftTicketQuery(leftTicketDTO, successHandler: successHandler, failHandler: failHandler)
        queryOperation.addDependency(logOperation)
        logOperation.addDependency(initOperation)
        
        Service.shareManager.operationQueue.addOperations([initOperation,logOperation,queryOperation], waitUntilFinished: false)
    }
    
    //leftTicket/init
    func getLeftTicketInit()->AFHTTPRequestOperation
    {
        Service.shareManager.responseSerializer = AFHTTPResponseSerializer()
        return Service.shareManager.OperationForGET(
            "https://kyfw.12306.cn/otn/leftTicket/init",
            parameters: nil,
            success: { (operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
                if let content = NSString(data: (responseObject as! NSData), encoding: NSUTF8StringEncoding) as? String
                {
                    // var CLeftTicketUrl = 'leftTicket/queryT';
                    if let matches = Regex("var CLeftTicketUrl = '([^']+)'").getMatches(content){
                        MainModel.CLeftTicketUrl = matches[0][0]
                        logger.debug("CLeftTicketUrl = \(MainModel.CLeftTicketUrl!)")
                    }
                    else{
                        logger.error("fail to get CLeftTicketUrl:\(content)")
                    }
                    
                    // var isSaveQueryLog='Y';
                    if let matches = Regex("var isSaveQueryLog='([^']+)'").getMatches(content){
                        let isSaveQueryLogStr = matches[0][0]
                        if isSaveQueryLogStr == "Y" {
                            MainModel.isSaveQueryLog = true
                        }
                        else{
                            MainModel.isSaveQueryLog = false
                        }
                        logger.debug("isSaveQueryLogStr = \(isSaveQueryLogStr) \(MainModel.isSaveQueryLog)")
                    }
                    else{
                        logger.error("fail to get isSaveQueryLog:\(content)")
                    }
                    
                    // src="/otn/dynamicJs/qdrtdtw"
                    if let matches = Regex("src=\"/otn/dynamicJs/([^\"]+)\"").getMatches(content){
                        MainModel.dynamicJs = matches[0][0]
                        logger.debug("dynamicJs = \(MainModel.dynamicJs)")
                    }
                    else{
                        logger.error("fail to get dynamicJs:\(content)")
                    }
                }
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                logger.error(error.localizedDescription)
            }
        )!
    }
    
    func getLeftTicketLog(leftTicketDTO:LeftTicketDTO,successHandler:()->(),failHandler:()->())->AFHTTPRequestOperation{
        let queryParam = "leftTicketDTO.train_date=\(leftTicketDTO.train_date!)&leftTicketDTO.from_station=\(leftTicketDTO.from_station!)&leftTicketDTO.to_station=\(leftTicketDTO.to_station!)&purpose_codes=\(leftTicketDTO.purpose_codes!)"
        let url = "https://kyfw.12306.cn/otn/leftTicket/log?" + queryParam
        
        setReferLeftTicketInit()
        Service.shareManager.responseSerializer = AFJSONResponseSerializer()
        return Service.shareManager.OperationForGET(url, parameters: nil,
            success: {(operation: AFHTTPRequestOperation!,responseObject: AnyObject!) in
//                Swift.print("request Header: \(Service.shareManager.requestSerializer.HTTPRequestHeaders)")
//                Swift.print("response Header: \(operation.response?.allHeaderFields)")
                
                let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies
                let cookieStr = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies!)
                Service.shareManager.requestSerializer.setValue(cookieStr["Cookie"], forHTTPHeaderField:"Cookie")
                
                Swift.print("url cookies str = \(cookieStr)")
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                logger.error(error.localizedDescription)
                failHandler()
            }
        )!
    }
    
    func getLeftTicketQuery(leftTicketDTO:LeftTicketDTO,successHandler:()->(),failHandler:()->())->AFHTTPRequestOperation{
        let queryParam = "leftTicketDTO.train_date=\(leftTicketDTO.train_date!)&leftTicketDTO.from_station=\(leftTicketDTO.from_station!)&leftTicketDTO.to_station=\(leftTicketDTO.to_station!)&purpose_codes=\(leftTicketDTO.purpose_codes!)"
        let url = "https://kyfw.12306.cn/otn/leftTicket/queryT?" + queryParam
        
        setReferLeftTicketInit()
        Service.shareManager.responseSerializer = AFJSONResponseSerializer()
        return Service.shareManager.OperationForGET(url, parameters: nil,
            success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in
                let jsonData = JSON(responseObject)["data"]
                guard jsonData.count > 0 else {
                    logger.error(jsonData.stringValue)
                    failHandler()
                    return
                }
                MainModel.leftTickets = [QueryLeftNewDTO]()
                for i in 0..<jsonData.count
                {
                    let leftTicket = QueryLeftNewDTO(jsonData: jsonData[i])
                    MainModel.leftTickets!.append(leftTicket)
                }
                successHandler()
                
            },
            failure: { (operation: AFHTTPRequestOperation!,error: NSError!) in
                logger.error(error.localizedDescription)
                failHandler()
            }
        )!
    }

}