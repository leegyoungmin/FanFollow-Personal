//
//  ChatRepositoryTests.swift
//  ServiceTests
//
//  Copyright (c) 2023 Minii All rights reserved.

import XCTest

import RxBlocking
import RxTest

@testable import FanFollow

final class ChatRepositoryTests: XCTestCase {
    private var successResponse: URLResponse!
    private var failureResponse: URLResponse!
    private var networkService: StubNetworkService!
    
    override func setUpWithError() throws {
        let url = URL(string: "https://qacasllvaxvrtwbkiavx.supabase.co/rest/v1/CHAT_ROOM")!
        
        self.successResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        self.failureResponse = HTTPURLResponse(
            url: url,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        let stubNetworkService = StubNetworkService(
            data: ChatDTO.data,
            error: nil,
            response: nil
        )
        
        networkService = stubNetworkService
    }
    
    override func tearDownWithError() throws {
        successResponse = nil
        failureResponse = nil
        networkService = nil
    }
    
    /// 정상적인 사용자ID를 전달하였을 때 정상적인 데이터를 반환하는지에 대한 테스트
    func test_FetchChattingListIsCorrectWhenSendCorrectData() {
        // given
        let userID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        networkService.response = successResponse
        
        // when
        let chatRepository = DefaultChatRepository(self.networkService)
        let chatListObservable = chatRepository.fetchChattingList(userID: userID)
        
        // then
        let value = try? chatListObservable.toBlocking().first()!.first!
        let result = (value?.fanID == userID || value?.creatorID == userID)
        
        XCTAssertEqual(result, true)
    }
    
    /// 정상적인 사용자ID를 전달하였을 때 에러를 방출하는지에 대한 테스트
    func test_FetchChattingListThrowErrorWhenSendCorrectData() throws {
        // given
        let userID = ""
        self.networkService.response = failureResponse
        self.networkService.error = NetworkError.unknown
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let chatListObservable = chatRepository.fetchChattingList(userID: userID)
        
        // then
        do {
            let _ = try chatListObservable.toBlocking().first()
        } catch let error {
            let error = error as? NetworkError
            let expected = NetworkError.unknown
            
            XCTAssertEqual(error, expected)
        }
    }
    
    /// 정상적인 사용자ID를 전달하였을 때 채팅방 생성 완료 이벤트가 방출되는가에 대한 테스트
    func test_CreateNewChatRoomIsCompletedWhenSendCorrectData() throws {
        // given
        let fanID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        let creatorID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        networkService.response = successResponse
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.createNewChatRoom(from: fanID, to: creatorID)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssert(true)
        case .failed(_, let error):
            XCTAssertThrowsError(error, "We expected Completed Event, But Occur Error Event")
        }
    }
    
    /// 정상적인 사용자ID를 전달하였을 때 채팅방 생성 에러 이벤트가 방출하는지에 대한 테스트
    func test_CreateNewChatRoomIsErrorWhenSendCorrectData() throws {
        // given
        let fanID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        let creatorID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        networkService.response = failureResponse
        networkService.error = NetworkError.unknown
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.createNewChatRoom(from: fanID, to: creatorID)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssertThrowsError(NetworkError.unknown, "We expected Error Event, But Occur Completed Event")
        case .failed:
            XCTAssert(true)
        }
    }
    
    /// 정상적인 데이터를 전달하였을 때 채팅방 떠나기 함수가 완료 이벤트를 방출하는지에 대한 테스트
    func test_LeaveChatRoomIsCompletedWhenSendCorrectData() throws {
        // given
        let chatID = "3538b47a-1113-4aff-96d9-6e2ec4b37d46"
        let fanID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        networkService.response = successResponse
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.leaveChatRoom(to: chatID, userID: fanID, isCreator: false)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssert(true)
        case .failed(_, let error):
            XCTAssertThrowsError(error, "We expected Completed Event, But Occur Error Event")
        }
    }
    
    /// 정상적인 데이터를 전달하였을 때 채팅방 떠나기 함수가 에러 이벤트를 방출하는지에 대한 테스트
    func test_LeaveChatRoomIsErrorWhenSendCorrectData() throws {
        // given
        let chatID = "3538b47a-1113-4aff-96d9-6e2ec4b37d46"
        let fanID = "5b587434-438c-49d8-ae3c-88bb27a891d4"
        networkService.response = failureResponse
        networkService.error = NetworkError.unknown
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.leaveChatRoom(to: chatID, userID: fanID, isCreator: false)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssertThrowsError(
                NetworkError.unknown,
                "We expected Error Event, But Occur OnCompleted Event"
            )
        case .failed:
            XCTAssertTrue(true)
        }
    }
    
    /// 정상적인 데이터를 전달하였을 때 채팅방 삭제 함수가 완료 이벤트를 방출하는지에 대한 테스트
    func test_DeleteChatRoomIsCompletedWhenSendCorrectData() throws {
        // given
        let chatID = "3538b47a-1113-4aff-96d9-6e2ec4b37d46"
        networkService.response = successResponse
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.deleteChatRoom(to: chatID)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssert(true)
        case .failed(_, let error):
            XCTAssertThrowsError(error, "We expected Completed Event, But Occur Error Event")
        }
    }
    
    /// 정상적인 데이터를 전달하였을 때 채팅방 떠나기 함수가 에러 이벤트를 방출하는지에 대한 테스트
    func test_DeleteChatRoomIsErrorWhenSendCorrectData() throws {
        // given
        let chatID = "3538b47a-1113-4aff-96d9-6e2ec4b37d46"
        networkService.response = failureResponse
        networkService.error = NetworkError.unknown
        
        //when
        let chatRepository = DefaultChatRepository(self.networkService)
        let observable = chatRepository.deleteChatRoom(to: chatID)
        
        //then
        let result = observable.toBlocking().materialize()
        
        switch result {
        case .completed:
            XCTAssertThrowsError(
                NetworkError.unknown,
                "We expected Error Event, But Occur OnCompleted Event"
            )
        case .failed:
            XCTAssertTrue(true)
        }
    }
}
