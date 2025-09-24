/*************************************************************************/
/*  game_center_saved_game.mm                                            */
/*************************************************************************/
/*                       This file is part of:                           */
/*                           GODOT ENGINE                                */
/*                      https://godotengine.org                          */
/*************************************************************************/
/* Copyright (c) 2007-2021 Juan Linietsky, Ariel Manzur.                 */
/* Copyright (c) 2014-2021 Godot Engine contributors (cf. AUTHORS.md).   */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#include "game_center_saved_game.h"

#include "game_center.h"

#import <GameKit/GameKit.h>

static void *_get_ptrw(GodotByteArray& arr);

#if VERSION_MAJOR == 4
typedef PackedByteArray GodotByteArray;
static void *_get_ptrw(GodotByteArray& arr) {
	return (void *) arr.ptrw();
}
#else
typedef PoolByteArray GodotByteArray;
static void *_get_ptrw(GodotByteArray& arr) {
	return (void *) arr.write().ptr();
}
#endif

void GameCenterSavedGame::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_name"), &GameCenterSavedGame::get_name);
	ClassDB::bind_method(D_METHOD("get_modification_date"), &GameCenterSavedGame::get_modification_date);
	ClassDB::bind_method(D_METHOD("get_device_name"), &GameCenterSavedGame::get_device_name);
	ClassDB::bind_method(D_METHOD("load_data"), &GameCenterSavedGame::load_data);

	ADD_PROPERTY(PropertyInfo(Variant::STRING, "name"), "", "get_name");
	ADD_PROPERTY(PropertyInfo(Variant::INT, "modification_date"), "", "get_modification_date");
	ADD_PROPERTY(PropertyInfo(Variant::STRING, "device_name"), "", "get_device_name");
};

String GameCenterSavedGame::get_name() const {
	return [saved_game.name UTF8String];
}

int64_t GameCenterSavedGame::get_modification_date() const {
	return saved_game.modificationDate.timeIntervalSince1970;
}

String GameCenterSavedGame::get_device_name() const {
	return [saved_game.deviceName UTF8String];
}

GKSavedGame *GameCenterSavedGame::get_saved_game() const {
	return saved_game;
}

void GameCenterSavedGame::load_data() {
	// make sure a reference is held while the async operation is in progress 
	reference();

	[saved_game loadDataWithCompletionHandler:^(NSData * _Nullable data, NSError * _Nullable error) {
		if (GameCenter::get_singleton()) {
			GodotByteArray gdata;
			if (data.bytes) {
				gdata.resize(data.length);
				memcpy(_get_ptrw(gdata), data.bytes, data.length);
			}
			GameCenter::get_singleton()->game_center_saved_game_loaded(this, gdata, error.code, [error.localizedDescription UTF8String]);
		}

		// release the reference held for the async operation
		unreference();
	}];
}

String GameCenterSavedGame::to_string() {
	return vformat("<GameCenterSavedGame: name=%s, modification_date=%d, device_name=%s>", get_name(), get_modification_date(), get_device_name());
}

GameCenterSavedGame::GameCenterSavedGame(GKSavedGame *saved_game) : saved_game(saved_game) {}

GameCenterSavedGame::~GameCenterSavedGame() {
	if (saved_game) {
		saved_game = nil;
	}
}
