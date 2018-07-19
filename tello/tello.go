package tello

import (
	"errors"
	"time"

	"gobot.io/x/gobot"
	"gobot.io/x/gobot/platforms/dji/tello"
)

var drone *tello.Driver

// InitDrone to tello
func InitDrone(port string) {
	drone = tello.NewDriver(port)
}

// ConnectedEventHandler は tello の ConnectedEvent のハンドラーです
type ConnectedEventHandler interface {
	Conected()
}

// VideoFrameEventHandler は tello の VideoFrameEvent のハンドラーです
type VideoFrameEventHandler interface {
	VideoFrame([]byte)
}

// RegisterOnConnectedEvent は tello への接続コールバックを登録します
func RegisterOnConnectedEvent(callback ConnectedEventHandler) (err error) {
	err = checkDroneInitialized()
	err = drone.On(tello.ConnectedEvent, func(data interface{}) {
		callback.Conected()
	})
	return err
}

// RegisterVideoFrameEvent は tello の VideoFrameEvent のハンドラーを登録します
func RegisterVideoFrameEvent(callback VideoFrameEventHandler) (err error) {
	err = checkDroneInitialized()
	err = drone.On(tello.VideoFrameEvent, func(data interface{}) {
		pkt := data.([]byte)
		callback.VideoFrame(pkt)
	})
	return err
}

// Start は tello との通信を開始します
func Start() (err error) {
	err = checkDroneInitialized()
	robot := gobot.NewRobot("tello",
		[]gobot.Connection{},
		[]gobot.Device{drone},
	)
	err = robot.Start()
	return err
}

// StartVideo は tello のビデオ機能を開始します
func StartVideo() (err error) {
	err = checkDroneInitialized()
	err = drone.StartVideo()
	gobot.Every(100*time.Millisecond, func() {
		drone.StartVideo()
	})
	return err
}

// TakeOff はドローンを離陸させます
func TakeOff() (err error) {
	err = checkDroneInitialized()
	err = drone.TakeOff()
	return err
}

// Land はドローンを着陸させます
func Land() (err error) {
	err = checkDroneInitialized()
	err = drone.Land()
	return err
}

// SetVideoEncoderRate は tello の VideoEncoderRate を設定します
func SetVideoEncoderRate(rate int) (err error) {
	err = checkDroneInitialized()
	err = drone.SetVideoEncoderRate(tello.VideoBitRate(rate))
	return err
}

func checkDroneInitialized() error {
	if drone == nil {
		return errors.New("InitDrone(string) を読んで下さい")
	}
	return nil
}
