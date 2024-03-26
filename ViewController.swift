import UIKit
import SwiftUI

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    /** Hold the price the user types in. */
    @IBOutlet weak var inputTextField: UITextField!
    
    /** Shows the output price. */
    @IBOutlet weak var outputLabel: UILabel!
    
    /** Scroll wheal for the year. */
    @IBOutlet weak var yearPicker: UIPickerView!
    
    /** Holds all of the years to put inside the picker. */
    var pickerYears = [String]()
    
    /** Holds the year the picker lands on. */
    var yearPicked = String()
    
    /** Stores CPI values from 1800 to 2023.
     CPI history [0] being 1800 and CPI history last 2023.
    */
    var CPI_history = [Double]()
    
    /** Holds the last full CPI year. */
    var CURRENT_YEAR: Int = Calendar.current.component(.year, from: Date())
    
    /** Holds the starting year. */
    var BASE_YEAR: Int = 1800
    
    
    @IBOutlet weak var reverse_toggle: UISwitch!
    
    /** Setup function for Input Field */
    func setupInputField(){
        /** Disables alphabet keyboard and enables numeric keyboard. */
        self.inputTextField.keyboardType = UIKeyboardType.decimalPad
        inputTextField.layer.borderColor = UIColor.lightGray.cgColor
        
        /** Launches keyboard from the get go. */
        inputTextField.becomeFirstResponder()
        
        inputTextField.layer.borderWidth = 2.0
        self.inputTextField.attributedPlaceholder = NSAttributedString(
                string: "$--",
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
            )
    }
    
    /** Setup function for picker. */
    func setupPicker(){
        /** Gets data from CSV file . Also removes the "\n" at the end of the last element */
        let csv_in = readDataFromCSV(fileName: "data", fileType: "csv")
        let data = csv_in?.filter { $0 != "\n" }
        
        /** Converts data from string to double */
        CPI_history = (data?.components(separatedBy: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) })!
        
        /** Limits the double to the 100th */
        for x in 0..<CPI_history.count{
            CPI_history[x] = Double(round(1000 * CPI_history[x]) / 1000)
        }
        
        /** Inserts all the years between now and 1800 */
        self.yearPicker.delegate = self
        self.yearPicker.dataSource = self
        for i in (BASE_YEAR...CURRENT_YEAR - 1).reversed(){
            pickerYears.append(String(i))
        }
    }
    
    /** Casts double into a dollar amount string.
         Example : 1234.56 -> $1,234.56
     */
    func double_to_usd(numb: Double) -> String{
        if #available(iOS 15.0, *) {
            return numb.formatted(.currency(code: "USD"))
        }
        return "iOS too old."
    }
    
    /** Given a double which is the calculated price with CPI, it will return the output string. */
    func getOutput(dynamicSum: Double) -> String{
        /** Casts double into Dollar formatted string. */
        let start_amount = self.double_to_usd(numb: Double(inputTextField.text!)!)
        let end_amount = self.double_to_usd(numb: dynamicSum)
        
        /** If the toggle is on, it will return reversed output.*/
        if reverse_toggle.isOn{
            return start_amount + " in " + yearPicked + " would feel like " + end_amount + " today."
        }
        
        /** Toggled off output. */
        return start_amount + " today would feel like " + end_amount + " in " + yearPicked
    }
    
    /** Setup functions. */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInputField()
        setupPicker()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /** Main calculations */
    @IBAction func EnterButton(_ sender: Any) {

        if !inputTextField.text!.isEmpty{

            /** If the user selects the first year without scrolling first, it will be an empty string. */
            if yearPicked.isEmpty{
                yearPicked = String(Int(CURRENT_YEAR) - 1)
            }
            
            /** Used for traversing CPI data. */
            let difference = CURRENT_YEAR - Int(yearPicked)!
            
            /** Two variables used in the mathematics of calculating CPI with price. */
            var runningSum = Double(inputTextField.text!)
            var dynamicSum = runningSum
            
            /** Goes through CPI history applying its index's as percentages. */
            for i in (CPI_history.count - difference)...(CPI_history.count - 1){
                
                /** Converted percentage into a decimal number. */
                let decimal = CPI_history[i] * 0.01
                
                /** Mathematics of applying CPI to price. */
                runningSum = runningSum! + (dynamicSum! * decimal)
                dynamicSum = runningSum
            }
            
            /** Gets the proper output based on toggle. */
            outputLabel.text = getOutput(dynamicSum: dynamicSum!)
            
            return
        }
        
        /** If the user does not put anything into the dollar amount field, it will default to 0 */
        inputTextField.text! = "0"
        
        return
        
    }
    
    /** YEAR PICKER FUNCTIONS */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerYears.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerYears[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        yearPicked = pickerYears[row]
    }
    
    /** Dismisses numeric keyboard. */
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /** CSV PARSHING FILES */
    func readDataFromCSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
            else {
                return nil
        }
        do {
            var contents = try String(contentsOfFile: filepath, encoding: .utf8)
            contents = cleanRows(file: contents)
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    func cleanRows(file:String)->String{
        var cleanFile = file
        cleanFile = cleanFile.replacingOccurrences(of: "\r", with: "\n")
        cleanFile = cleanFile.replacingOccurrences(of: "\n\n", with: "\n")
        return cleanFile
    }
    
    func csv(data: String) -> [[String]] {
        var result: [[String]] = []
        let rows = data.components(separatedBy: "\n")
        for row in rows {
            let columns = row.components(separatedBy: ";")
            result.append(columns)
        }
        return result
    }
}

