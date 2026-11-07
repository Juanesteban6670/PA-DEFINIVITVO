package Com.Backend.CartagenaSegura.Controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class WelcomeController {

    @GetMapping(value = {
        "/",
        "/Login",
        "/Register",
        "/ForgotPassword",
        "/ResetPassword",
        "/App",
        "/App/**",
        "/Admin",
        "/Admin/**"
    })
    public String forwardSpa() {
        return "forward:/index.html";
    }
}
