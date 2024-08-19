/*
 * RUCA: Rust calculator
 *
 * Meant to be similar to bc, and intended to
 * have less overhead than piping an expression
 * to luajit which has a more natural-feeling
 * syntax
 */

//use std::ops::*;
use std::process::ExitCode;

/*
enum Ops {
    Mod,
    Mul,
    Div,
    Add,
    Sub
}
*/

fn main() -> ExitCode {

    let args = std::env::args();
    let max = args.len()-2;

    let expression = args
        .enumerate()
        .map(|(i,x)| {
            if i < max {
                x + " "
            } else if i > 0 {
                x
            } else {
                String::new()
            }
        })
        .collect::<Vec<String>>()
        .concat()
        .trim()
        .to_string();
    let result = parse_float(expression);

    if let Err(e) = result {
        return e;
    }
    if let Ok(num) = result {
        println!("{}", num);
    }


    ExitCode::from(0)
}

/*
fn parse_expression<T>(expression: String) -> T
where T: Add + Mul + Sub + Div + std::str::FromStr + std::default::Default {
    expression.parse::<T>().unwrap_or(T::default())
}
*/

fn parse_float(expression: String) -> Result<f64,ExitCode> {

    /*
    fn exitval(code: u8) -> Result<f64, ExitCode> {
        Err(ExitCode::from(code))
    }

    if let Ok(num) = expression.trim().parse::<f64>() {
        return Ok(num);
    }
    */

    let mut expression = expression.clone();

    let mut resolved = false;
    // let mut quantities: Vec<(usize, String)> = Vec::with_capacity(255);
    // depth, expression - where depth is 0 at the deepest, and increases for surrounding contexts

    //let mut depth = 0;

    let mut total: f64 = 0.0;

 
    while !resolved {
        resolved = match evaluate_or_parse(expression.clone()) {
            Ok(num) => {
                total = num;
                true
            },
            Err(expr) => {
                expression = expr;
                #[cfg(debug_assertions)]
		eprintln!("Resolver checkpoint: expression = {:?}", expression);
                false
            },
        };
        //std::thread::sleep(std::time::Duration::from_millis(800));
    }
    


    Ok(total)

}

fn evaluate_or_parse(expression: String) -> Result<f64, String> {
    
    let mut result = 0.0;

    if let Ok(num) = expression.trim().parse::<f64>() {
        result = num;
    } else {
        #[cfg(debug_assertions)]
		eprintln!("Sending {:?} to `evaluate` in `evaluate_or_parse`", expression);
        return Err(evaluate(expression));
    }

    // to make compile
    Ok(result)
}

fn evaluate(expression: String/*, pre: usize, post: usize*/) -> String {

    #[cfg(debug_assertions)]
		eprintln!("`evaluate({:?})`", expression);

    let expression = expression.trim().to_string();//[pre..post].to_string();

    let len = expression.chars().count();

    let mut expr = String::new();

    //let mut result = 0.0;

    let mut converted1 = 0.0;
    let mut converted2 = 0.0;

    let mut pre = 0;
    let mut post = len-1;
    let len = expression.len();

    macro_rules! operate {
        ($i:expr, $ch:expr) => {
            #[cfg(debug_assertions)]
		eprintln!("Entered operate with values i = `{}`, ch = `{}`", $i, $ch);
            let (start1, end1, found_quantity1) = find_number(&expression[..$i], false);
            let (start2, end2, found_quantity2) = find_number(&expression[$i+1..], true);

            let offset = $i+1;

            pre = start1;
            post = end2+offset;
            post += if found_quantity2 {
                1
            } else {
                0
            };
            pre -= if found_quantity1 {
                1
            } else {
                0
            };

            let pre_attempt1 = expression[start1..=end1].to_string();
            let attempt1 = &pre_attempt1.trim().parse::<f64>();
            let pre_attempt2 = expression[start2+offset..=end2+offset].to_string();
            let attempt2 = &pre_attempt2.trim().parse::<f64>();

            #[cfg(debug_assertions)]
		eprintln!("Trying operation {} {} {}", pre_attempt1.trim(), $ch, pre_attempt2.trim());

            if let Ok(num1) = &attempt1 {
                #[cfg(debug_assertions)]
		eprintln!("converted1 is {num1}");
                converted1 = *num1;
            } else {
                #[cfg(debug_assertions)]
		eprintln!("Error. Trying converted1 as quantity.");
                converted1 = 
                    if let Ok(num) = evaluate(pre_attempt1).parse::<f64>() {
                        num
                    } else {
                        #[cfg(debug_assertions)]
		eprintln!("Error processing.");
                        panic!();
                    };
            }
            if let Ok(num2) = &attempt2 {
                #[cfg(debug_assertions)]
		eprintln!("converted2 is {num2}");
                converted2 = *num2;
            } else {
                #[cfg(debug_assertions)]
		eprintln!("Error. Trying converted2 as quantity ({:?}).", &pre_attempt2);
                converted2 = 
                    if let Ok(num) = evaluate(pre_attempt2).parse::<f64>() {
                        num
                    } else {
                        #[cfg(debug_assertions)]
		eprintln!("Error processing.");
                        panic!();
                    };
            }


            let calc_result = (
                match $ch {
                '^' => converted1.powf(converted2),
                '*' => converted1 * converted2,
                '/' => converted1 / converted2,
                '+' => converted1 + converted2,
                '-' => converted1 - converted2,
                '%' => converted1 % converted2,
                _ => 0.0,

            });

            #[cfg(debug_assertions)]
		eprintln!("{} {} {} = {}", converted1, $ch, converted2, calc_result);

            let pre_calc = expression[..pre].to_string();
            let post_calc = expression[post+1..len].to_string();

            #[cfg(debug_assertions)]
		eprintln!("`{}` .. `{}` .. `{}` > `expr`", &pre_calc, &calc_result, &post_calc);

            expr = pre_calc +
            calc_result.to_string().as_str() +
            post_calc.as_str();


        }
    }

    let mut last_open = 0;
    let mut next_close = len-1;

    let mut break_all = false;

    for pass in 0..4 {
        #[cfg(debug_assertions)]
		eprintln!("Pass {pass}...");
        for (i,ch) in expression.chars().enumerate() {
            match ch {
                '(' if pass == 0 => {
                    last_open = i;
                },
                ')' if pass == 0 => {
                    if last_open < i {
                        next_close = i;
                    }

                    let mini_expr = expression[last_open+1..next_close].to_string();
                    #[cfg(debug_assertions)]
		eprintln!("(In pass 0) Found grouped quantity {:?}, entering and evaluating...", mini_expr);

                    let beginning = expression[..last_open].to_string();
                    let middle = evaluate(mini_expr);
                    let end = expression[next_close+1..].to_string();

                    #[cfg(debug_assertions)]
		eprintln!("(In pass 0) {} .. {} .. {} > return", &beginning, &middle, &end);

                    return 
                        beginning +
                        middle.as_str() +
                        end.as_str();
                },
                '^' if pass == 1 => {
                    operate!(i,ch);
                    break_all = true;
                    break;
                },
                '*' | '%' | '/' if pass == 2 => {
                    operate!(i,ch);
                    break_all = true;
                    break;
                },
                '+' | '-' if pass == 3 => {
                    operate!(i,ch);
                    break_all = true;
                    break;
                }
                _ => {
                    if i == len-1 && pass == 3 {
                        #[cfg(debug_assertions)]
		eprintln!("No calculation symbol detected for {:?}", expression);
                        return expression;
                    }
                },
            }
        }
        if break_all {
            break;
        }
    }


    #[cfg(debug_assertions)]
		eprintln!("New expression: {:?}", expr.to_string());

    expr
}

fn find_number(string: &str, forward: bool)
-> (usize, usize, bool) // Location and parentheses depth, or
                                       // failure code
{

    #[cfg(debug_assertions)]
		eprintln!("find_number got string \"{}\"", &string);
    let mut inside_number = false;
    let mut period_found = false;

    let mut is_quantity = false;

    let mut paren_depth: isize = 0;

    let len = string.chars().count();
    let (mut first, mut last) = (0, len-1);

    fn get_char(string: &str, index: usize) -> char {
        string[index..index+1].to_string().chars().next().unwrap()
    }

    macro_rules! printfirst {
        ($idx:expr) => {
            #[cfg(debug_assertions)]
		eprintln!("first char changed to {:?}", get_char(string, $idx));
        }
    }
    macro_rules! printlast {
        ($idx:expr) => {
            #[cfg(debug_assertions)]
		eprintln!("last char changed to {:?}", get_char(string, $idx));
        }
    }


    if forward {
        #[cfg(debug_assertions)]
		eprintln!("Searching forward...");
        for (i, ch) in string.chars().enumerate() {
            //{ dbg!(&i, &ch); }
            match ch {
                '(' => {
                    if paren_depth == 0 {
                        #[cfg(debug_assertions)]
		eprintln!("Encountered (");
                        first = i+1;
                        printfirst!(first);
                        is_quantity = true;
                    }
                    paren_depth += 1;
                },
                '0'..='9' | '.' => {
                    #[cfg(debug_assertions)]
		eprintln!("Encountered {}", ch);
                    if !inside_number {
                        inside_number = true;
                        first = i;
                        printfirst!(first);
                    } else if paren_depth > 0 {
                        #[cfg(debug_assertions)]
                        eprint!(" .");
                    } else {
                        #[cfg(debug_assertions)]
                        eprint!(" .");
                    }
                    
                },
               _ => {
                  #[cfg(debug_assertions)]
		eprintln!("Encountered other character {:?}", ch);
                  if paren_depth > 0 && ch == ')' { 
                      #[cfg(debug_assertions)]
		eprintln!("Closing ) found -- current paren_depth is {paren_depth}");
                      last = i-1;
                      printlast!(last);
                      paren_depth -= 1;
                  }
                  if paren_depth > 0 {
                      if inside_number && !matches!(get_char(string, i-1), '0'..='9' | '.') {
                        inside_number = false;
                      }
                  }
                  if paren_depth == 0 && inside_number {
                      inside_number = false;
                      period_found = false;
                      last = i-1;
                      printlast!(last);
                      #[cfg(debug_assertions)]
		eprintln!("Current character is {}, last character is {}", ch, &string[i-1..i]);
                      return (first, last, false);
                  }
                }
            }
            if i == len - 1 && inside_number {
                if ch != ')' {
                    last = i;
                    printlast!(last);
                } else {
                    last = i - 1;
                    printlast!(last);
                }
            }
        }
    } else {
        #[cfg(debug_assertions)]
		eprintln!("Searching backward...");
        for (i, ch) in string.to_string().chars().rev().enumerate() {
            let i = len - i - 1;


            //{ dbg!(&i, &ch, &paren_depth); }
            match ch {
                ')' => {
                    if paren_depth == 0 {
                        #[cfg(debug_assertions)]
		eprintln!("Encountered )");
                        last = i-1;
                        printlast!(last);
                    }
                    paren_depth += 1;
                    is_quantity = true;
                },
                '0'..='9' | '.' => {

                    #[cfg(debug_assertions)]
		eprintln!("Encountered {}", ch);
                    if !inside_number {
                        inside_number = true;
                        last = i;
                        printlast!(last);
                    } else if paren_depth > 0 {
                        #[cfg(debug_assertions)]
                        eprint!(" .");
                    } else {
                        #[cfg(debug_assertions)]
                        eprint!(" .");
                    } 
                     
                },
                _ => {
                  #[cfg(debug_assertions)]
            		eprintln!("Encountered other character {:?}", ch);
                  if paren_depth > 0 && ch == '(' { 
                      #[cfg(debug_assertions)]
                		eprintln!("Closing ( found -- current paren_depth is {paren_depth}");
                      first=i+1;
                      printfirst!(first);
                      paren_depth -= 1;
                  }
                  if paren_depth > 0 {
                      if inside_number && !matches!(get_char(string, i+1), '0'..='9' | '.') {
                        inside_number = false;
                      }
                  } else if paren_depth == 0 && inside_number {
                      #[cfg(debug_assertions)]
		eprintln!("All parentheses matched.");
                      inside_number = false;
                      period_found = false;
                      first=i+1;
                      printfirst!(first);
                      return (first, last, false);
                  }
                  
                },
            }

            if i == 0 && inside_number {
                return (0,last, false);
            }

        }
    }

        #[cfg(debug_assertions)]
		eprintln!("First char: {:?} -- Last char: {:?} -- paren depth {:?}",
        get_char(string, first),
        get_char(string, last),
        paren_depth
    );

    if paren_depth != 0 {
        #[cfg(debug_assertions)]
		eprintln!("Error, mismatched parentheses.");
        panic!();
    }

    (first, last, is_quantity)
}
