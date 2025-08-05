namespace ManejoPresupuestos.Models
{
    public class ResultProcedureGeneric
    {
        public string result { get; set; }
        public string message { get; set; }
        public int elementoId { get; set; }
    }

    public static class ResultProcedureType
    {
        public const string SUCCESS = "success";
        public const string ERROR = "error";
    }
}
