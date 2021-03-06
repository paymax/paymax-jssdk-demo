<%@ page import="java.io.IOException" %>
<%@ page import="java.io.ByteArrayOutputStream" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Date" %>
<%@ page import="com.alibaba.fastjson.JSONObject" %>
<%@ page import="java.util.UUID" %>
<%@ page import="java.security.spec.PKCS8EncodedKeySpec" %>
<%@ page import="java.security.KeyFactory" %>
<%@ page import="java.security.PrivateKey" %>
<%@ page import="sun.misc.BASE64Decoder" %>
<%@ page import="sun.misc.BASE64Encoder" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
	/* *
	 Paymax 聚合收银台demo
	 注：本DEMO或文档中所示的默认配置参数仅供参考，接入方须视各自系统及交易情况进行相应的调整。如因采用默认配置参数导致交易异常及造成相关损失的，我司不承担相关责任。
	 * */
%>
<%!
    //编码必须使用UTF-8,因为服务端使用UTF-8解码
    public static final String CHARSET = "UTF-8";
    //Paymax提供给商户的SecretKey，登录网站后查看
    public static final String AUTHORIZATION = "55970fdbbf10459f966a8e276afa86fa";
    //商户自己的私钥【用com.Paymax.sign.RSAKeyGenerateUtil生成RSA秘钥对，公钥通过Paymax网站上传到Paymax，私钥设置到下面的变量中】
    public static final String PRIVATE_KEY = "MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAONMS7MhjNAEUd+JioKWQL375tYsL3LlrwHlXWmQe4BR+5LTmvpHxXYEsinNkTr5dlfm65QYPbDkf6/80e0HEhkG1ir0RnW/cPJy6f34NzLUgzqimYRmrcOFr1Wxyr1x0byyO40DHr/MXk7ea/DgE+ste3gTQB/B4j28Kfv5REclAgMBAAECgYBOJlxcsatdli6kQgEKlyiZabPbbYO+6HO8niT498FOxGFQAUtmxCiDRGgRcWl+smjbHj1fRNppKJcyZiWzblvs8s+4UmQd8KvNZtMmyZn8aVZfGHvpEoB6dbFaWxxj61/rhbBwRRISIzypiUgBp71JuCkFaGnV9YLfQmvKv52fXQJBAP4bViLjy7OUXh7dWQhe6tPDjB7nIA6YbypkKFm/yEZue8Ek90MvwFCXRdxBbuxXFViHsrrT01A7DUOWJL/1eocCQQDk/dOIaHF7VBYNw2Rol+XOHV80QoYsPAmKrtj+ZSc6rnz3irIuSqVOjRiYt6XA/PmUhrtXuizA/VrJrxUuyH/zAkEA6IKc83nax2wIH1fMgsNPPgudKB22EITcmz5gSZcZq5CmvlmTwq9r2pJAg0SAOdOJHaO1IAx5O918yo4U/Gyi+wJAZZnRf1aH82ZtmpG1PUsYJYmWskNJ8Np6iVPm54jODRVaUSLyx+NK0T19SlVBcA1OV34oJVZvgPlojM/oICfJzQJBANMbFW0/HtHQ5sZFncS/9/DFUy0f0Q4EYYD5oo7hx5vGNKMdOTvgFRppYw6z0RsKiHDoUnORxK4JIl+EhSMkbOs=";

    /**
     * 签名加密算法
     * @param content       内容
     * @param privateKey    私钥
     * @return
     */
    public String sign(String content, String privateKey) {
        try {
            BASE64Decoder decoder = new BASE64Decoder();
            byte[] result = decoder.decodeBuffer(privateKey);

            PKCS8EncodedKeySpec priPKCS8 = new PKCS8EncodedKeySpec(result);
            KeyFactory keyf = KeyFactory.getInstance("RSA");
            PrivateKey priKey = keyf.generatePrivate(priPKCS8);

            java.security.Signature signature = java.security.Signature
                    .getInstance("SHA1WithRSA");// 摘要加密算法;

            signature.initSign(priKey);
            signature.update(content.getBytes(CHARSET)); //数据

            byte[] signed = signature.sign();

            return new BASE64Encoder().encode(signed).replaceAll("[\\s*\t\n\r]", "");
        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }

    /**
     * 按照 Paymax 的签名要求,组装数据并签名
     * @param nonce
     * @param timestamp
     * @param authorization
     * @param request_data
     * @return
     * @throws IOException
     */
    public String signData(String nonce,Long timestamp, String authorization,String request_data) throws IOException {

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        out.write("POST".toLowerCase().getBytes(CHARSET)); //请求方法必须是POST
        out.write('\n');//method

        out.write("/js/charges".getBytes(CHARSET)); //请求URL固定为 "/js/charges"
        out.write('\n');//uri path
        out.write(nonce.getBytes(CHARSET)); //nonce:8~128位的随机字符串,由字⺟数字组成,不允许特殊字符
        out.write('\n');
        out.write(timestamp.toString().getBytes(CHARSET)); //timestamp:13位的时间戳,标准北京时间，时区为东⼋区，⾃1970年1⽉1⽇0点0分0秒 以来的毫秒数
        out.write('\n');
        out.write(authorization.getBytes(CHARSET));  //Authorization: 商户secretkey,Paymax 提供给商户的唯⼀标识,从Paymax商户后台的个⼈中⼼获取
        out.write('\n');
        byte[] data = request_data.getBytes(CHARSET); //request_data,请求数据对象,JSON格式，数据会放在POST请求request body中传输到后台
        out.write(data);//body
        out.close();
        String toSignString = out.toString(CHARSET);
        System.out.println("signData:"+toSignString);
        return sign(toSignString, PRIVATE_KEY);
    }

    public String generateUUID(){
        String str = UUID.randomUUID().toString();
        // 去掉"-"符号
        String temp = str.replaceAll("-","");
        return temp;
    }
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; UTF-8">
        <meta name="viewport" content="width=device-width,initial-scale=1.0,minimum-scale=1.0,maximum-scale=1.0,user-scalable=no">

        <title>Paymax demo</title>

        <!--Step 1. 嵌入Paymax JS SDK -->
        <script type='text/javascript' src='http://dev.paymax.cc/merchant-api/js/config?config=app_49b0f1dd741646d2b277524de2785836'></script>
        <%--<script type='text/javascript' src='https://www.paymax.cc/merchant-api/js/config?config=app_7hqF2S6GYXET457i'></script>--%>

    </head>
    <body>
        <button id="charge">Paymax 体验支付</button>
    </body>


    <%
        //构造参数
        Map<String,Object> map = new java.util.HashMap();

        Map<String,String> extra = new java.util.HashMap();
        extra.put("return_url", "http://www.paymax.cc");
        extra.put("user_id", "100");
        extra.put("show_url", "http://www.paymax.cc");

        map.put("time_expire",(new Date().getTime()+10*60*1000));

        map.put("title","Paymax demo");
        map.put("subject","subject1");
        map.put("body","body1");
        map.put("amount",0.01);
        map.put("order_no", generateUUID());
        map.put("client_ip","127.0.0.1");
        map.put("extra",extra);

        String nonce = generateUUID();
        Long timestamp = new Date().getTime();
        //JSON格式数据
        String requestBody = JSONObject.toJSONString(map);
        System.out.println("requestBody:"+requestBody);
        //Step 2. 根据订单数据,生成支付参数,并且签名 sign
        //注:签名详细说明见Paymax集合收银台技术对接文档
        String sign = signData(nonce,timestamp,AUTHORIZATION,requestBody);
        System.out.println("sign:"+sign);
    %>

    <script type="text/javascript">
    document.getElementById("charge").onclick = function() {
        /**
        * Step 3. 用户确认支付的时候,出发按钮绑定的 Paymax.charge事件,传入参数
        * 注: sign,使用上面的签名值
        */
        Paymax.charge({
            "debug" : false,
            "Authorization": "<%= AUTHORIZATION %>",
            "nonce": "<%= nonce %>",
            "timestamp": "<%= timestamp %>",
            "sign": "<%= sign %>", //商品信息hash值
            "request_data" : <%= requestBody %>
        },{ wxJsApiFinish: function(response) {},
            wxJsApiSuccess: function(response) {},
            wxJsApiFail: function(response) {},
            dataError: function(msg) {}
        });
        /**
        * Paymax.charge调用错误返回：默认行为console.log(err)
        */
//        Paymax.error = function(err) {
//            //err 为object
//        }
    };
</script>
</html>
