using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{

    public class ImpresoraEdicionViewModel
    {
        public int ImpresoraId { get; set; }

        [Required(ErrorMessage = "El nombre es requerido.")]
        [StringLength(150)]
        public string Nombre { get; set; } = ""; // <—

        [StringLength(150)]
        public string? Modelo { get; set; }

        [StringLength(500)]
        public string? Notas { get; set; }
    }

}
