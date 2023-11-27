package main

import (
	"fmt"
	"log"
	"os"
	"strconv"

	rtctokenbuilder "github.com/AgoraIO-Community/go-tokenbuilder/rtctokenbuilder"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

var appID, appCertificate string

func main() {
	if err := godotenv.Load(); err != nil {
		log.Print("No .env file found")
	}
	appIDEnv, appIDExists := os.LookupEnv("APP_ID")
	appCertEnv, appCertExists := os.LookupEnv("APP_CERTIFICATE")

	if !appIDExists || !appCertExists {
		log.Fatal("FATAL ERROR: ENV not properly configured, check APP_ID and APP_CERTIFICATE")
	} else {
		appID = appIDEnv
		appCertificate = appCertEnv
	}

	api := gin.Default()

	api.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	api.GET("rtc/:channelName/:role/:tokenType/:rtcuid/", getRtcToken)
	// api.GET("rtm/:uid/", getRtmToken)
	// api.GET("rte/:channelName/:role/:tokenType/:uid/", getBothTokens)
	api.Run(":8080")
}

func getRtcToken(c *gin.Context) {
	log.Println("Generating RTC token")
	// get param values
	channelName, tokenType, uidStr, _, role, expire, err := parseRtcParams(c)

	if err != nil {
		c.Error(err)
		c.AbortWithStatusJSON(400, gin.H{
			"message": "Error Generating RTC token: " + err.Error(),
			"status":  400,
		})
		return
	}

	rtcToken, tokenErr := generateRtcToken(channelName, uidStr, tokenType, role, expire)

	if tokenErr != nil {
		log.Println(tokenErr) // token failed to generate
		c.Error(tokenErr)
		errMsg := "Error Generating RTC token - " + tokenErr.Error()
		c.AbortWithStatusJSON(400, gin.H{
			"status": 400,
			"error":  errMsg,
		})
	} else {
		log.Println("RTC Token generated")
		c.JSON(200, gin.H{
			"rtcToken": rtcToken,
		})
	}
}

// func getRtmToken(c *gin.Context) {
// 	log.Printf("rtm token\n")
// 	// get param values
// 	uidStr, expireTimestamp, err := parseRtmParams(c)

// 	if err != nil {
// 		c.Error(err)
// 		c.AbortWithStatusJSON(400, gin.H{
// 			"message": "Error Generating RTC token: " + err.Error(),
// 			"status":  400,
// 		})
// 		return
// 	}

// 	rtmToken, tokenErr := rtmtokenbuilder.BuildToken(appID, appCertificate, uidStr, rtmtokenbuilder.RoleRtmUser, expireTimestamp)

// 	if tokenErr != nil {
// 		log.Println(err) // token failed to generate
// 		c.Error(err)
// 		errMsg := "Error Generating RTM token: " + tokenErr.Error()
// 		c.AbortWithStatusJSON(400, gin.H{
// 			"error":  errMsg,
// 			"status": 400,
// 		})
// 	} else {
// 		log.Println("RTM Token generated")
// 		c.JSON(200, gin.H{
// 			"rtmToken": rtmToken,
// 		})
// 	}
// }

// func getBothTokens(c *gin.Context) {
// 	log.Printf("dual token\n")
// 	// get rtc param values
// 	channelName, tokentype, uidStr, role, expireTimestamp, rtcParamErr := parseRtcParams(c)

// 	if rtcParamErr != nil {
// 		c.Error(rtcParamErr)
// 		c.AbortWithStatusJSON(400, gin.H{
// 			"message": "Error Generating RTC token: " + rtcParamErr.Error(),
// 			"status":  400,
// 		})
// 		return
// 	}
// 	// generate the rtcToken
// 	rtcToken, rtcTokenErr := generateRtcToken(channelName, uidStr, tokentype, role, expireTimestamp)
// 	// generate rtmToken
// 	rtmToken, rtmTokenErr := rtmtokenbuilder.BuildToken(appID, appCertificate, uidStr, rtmtokenbuilder.RoleRtmUser, expireTimestamp)

// 	if rtcTokenErr != nil {
// 		log.Println(rtcTokenErr) // token failed to generate
// 		c.Error(rtcTokenErr)
// 		errMsg := "Error Generating RTC token - " + rtcTokenErr.Error()
// 		c.AbortWithStatusJSON(400, gin.H{
// 			"status": 400,
// 			"error":  errMsg,
// 		})
// 	} else if rtmTokenErr != nil {
// 		log.Println(rtmTokenErr) // token failed to generate
// 		c.Error(rtmTokenErr)
// 		errMsg := "Error Generating RTC token - " + rtmTokenErr.Error()
// 		c.AbortWithStatusJSON(400, gin.H{
// 			"status": 400,
// 			"error":  errMsg,
// 		})
// 	} else {
// 		log.Println("RTC Token generated")
// 		c.JSON(200, gin.H{
// 			"rtcToken": rtcToken,
// 			"rtmToken": rtmToken,
// 		})
// 	}

// }
func parseRtcParams(c *gin.Context) (channelName, tokenType, uidStr string, rtmuid string, role rtctokenbuilder.Role, expire uint32, err error) {
	// get param values
	channelName = c.Param("channelName")
	roleStr := c.Param("role")
	tokenType = c.Param("tokenType")
	uidStr = c.Param("rtcuid")
	rtmuid = c.Param("rtmuid")

	if uidStr == "" {
		// If the uid is missing, just set to 0,
		// meaning it allows for any user ID
		uidStr = "0"
	}
	if rtmuid == "" && uidStr != "0" {
		rtmuid = uidStr
	}

	if roleStr == "publisher" {
		role = rtctokenbuilder.RolePublisher
	} else {
		// Making an assumption that !publisher == subscriber
		role = rtctokenbuilder.RoleSubscriber
	}

	expireTime := c.DefaultQuery("expiry", "3600")
	expireTime64, parseErr := strconv.ParseUint(expireTime, 10, 64)
	if parseErr != nil {
		// if string conversion fails return an error
		err = fmt.Errorf("failed to parse expireTime: %s, causing error: %s", expireTime, parseErr)
	}
	expire = uint32(expireTime64)

	return channelName, tokenType, uidStr, rtmuid, role, expire, err
}

// func parseRtmParams(c *gin.Context) (uidStr string, expireTimestamp uint32, err error) {
// 	// get param values
// 	uidStr = c.Param("uid")
// 	expireTime := c.DefaultQuery("expiry", "3600")

// 	expireTime64, parseErr := strconv.ParseUint(expireTime, 10, 64)
// 	if parseErr != nil {
// 		// if string conversion fails return an error
// 		err = fmt.Errorf("failed to parse expireTime: %s, causing error: %s", expireTime, parseErr)
// 	}

// 	// set timestamps
// 	expireTimeInSeconds := uint32(expireTime64)
// 	currentTimestamp := uint32(time.Now().UTC().Unix())
// 	expireTimestamp = currentTimestamp + expireTimeInSeconds

// 	// check if string conversion fails
// 	return uidStr, expireTimestamp, err
// }

func generateRtcToken(channelName, uidStr, tokenType string, role rtctokenbuilder.Role, expireDelta uint32) (rtcToken string, err error) {
	if tokenType == "userAccount" {
		log.Printf("Building Token for userAccount: %s\n", uidStr)
		rtcToken, err = rtctokenbuilder.BuildTokenWithAccount(appID, appCertificate, channelName, uidStr, role, expireDelta)
		return rtcToken, err
	} else if tokenType == "uid" {
		uid64, parseErr := strconv.ParseUint(uidStr, 10, 64)
		// check if conversion fails
		if parseErr != nil {
			err = fmt.Errorf("failed to parse uidStr: %s, to uint causing error: %s", uidStr, parseErr)
			return "", err
		}

		uid := uint32(uid64) // convert uid from uint64 to uint 32
		log.Printf("Building Token for uid: %d\n", uid)
		rtcToken, err = rtctokenbuilder.BuildTokenWithUid(appID, appCertificate, channelName, uid, role, expireDelta)
		return rtcToken, err
	} else {
		err = fmt.Errorf("failed to generate RTC token for Unknown Tokentype: %s", tokenType)
		log.Println(err)
		return "", err
	}
}
