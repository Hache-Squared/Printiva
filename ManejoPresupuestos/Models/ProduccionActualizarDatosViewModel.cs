using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class ProduccionActualizarDatosViewModel
    {
        [Required]
        public int ProduccionItemId { get; set; }

        public int? ImpresoraId { get; set; }
        public string? NotasOperativas { get; set; }
        public decimal? PesoEstimadoGr { get; set; }
        public decimal? PesoRealGr { get; set; }
        public DateTime? FechaInicio { get; set; }
        public DateTime? FechaFin { get; set; }
    }
}
